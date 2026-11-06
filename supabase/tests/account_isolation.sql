-- Run as database owner in a DEVELOPMENT Supabase project after the migration.
-- All fixtures and changes are rolled back. Fails immediately if an assertion fails.
begin;
insert into auth.users (id, email, raw_user_meta_data) values
 ('10000000-0000-0000-0000-000000000001', 'farmcare-test-a@example.invalid', '{"name":"Farm A"}'),
 ('10000000-0000-0000-0000-000000000002', 'farmcare-test-b@example.invalid', '{"name":"Farm B"}');

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
insert into public.animals (id, owner_id, name, species, breed, weight, feed_type, feed_schedule,
 vaccination_type, vaccination_frequency, last_vaccination_date)
values ('20000000-0000-0000-0000-000000000001', auth.uid(), 'Bessie', 'Cow', 'Holstein', 400,
 'Hay', 6, 'Test vaccination', 6, now());

do $$
begin
    if (select count(*) from public.profiles) <> 1 then raise exception 'Profile isolation failed'; end if;
    if (select name from public.profiles) <> 'Farm A' then raise exception 'Profile trigger failed'; end if;
    if (select count(*) from public.animals) <> 1 then raise exception 'Owner cannot see animal'; end if;
    begin
        update public.animals set owner_id = '10000000-0000-0000-0000-000000000002';
        raise exception 'Ownership transfer was allowed';
    exception when insufficient_privilege then null;
    end;
end $$;

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', true);
do $$
begin
    if exists (select 1 from public.animals) then raise exception 'Other account can read animals'; end if;
    update public.animals set name = 'Unauthorized';
    if found then raise exception 'Other account can update animals'; end if;
    begin
        insert into public.animals (id, owner_id, name, species, breed, weight, feed_type, feed_schedule,
            vaccination_type, vaccination_frequency, last_vaccination_date)
        values ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001',
            'Forged', 'Cow', 'Holstein', 400, 'Hay', 6, 'Test', 6, now());
        raise exception 'Other account can insert animals for first account';
    exception when insufficient_privilege then null;
    end;
    begin
        insert into public.animals (id, owner_id, name, species, breed, weight, feed_type, feed_schedule,
            vaccination_type, vaccination_frequency, last_vaccination_date)
        values ('20000000-0000-0000-0000-000000000001', auth.uid(), 'Hijacked', 'Cow', 'Holstein', 400,
            'Hay', 6, 'Test', 6, now())
        on conflict (id) do update set owner_id = excluded.owner_id, name = excluded.name;
        raise exception 'Cross-account upsert was allowed';
    exception when insufficient_privilege then null;
    end;
end $$;

select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
update public.animals set deleted_at = now();
-- Simulate an upsert from a stale offline device after deletion.
insert into public.animals (id, owner_id, name, species, breed, weight, feed_type, feed_schedule,
 vaccination_type, vaccination_frequency, last_vaccination_date)
values ('20000000-0000-0000-0000-000000000001', auth.uid(), 'Stale', 'Cow', 'Holstein', 400,
 'Hay', 6, 'Test vaccination', 6, now())
on conflict (id) do update set name = excluded.name, deleted_at = excluded.deleted_at;
do $$
begin
    if exists (select 1 from public.animals where deleted_at is null or name <> 'Bessie') then
        raise exception 'Stale upload resurrected or modified a deleted animal';
    end if;
    begin
        delete from public.animals;
        raise exception 'Client hard deletion was allowed';
    exception when insufficient_privilege then null;
    end;
end $$;
set local role anon;
do $$
begin
    begin
        perform * from public.animals;
        raise exception 'Anonymous reads were allowed';
    exception when insufficient_privilege then null;
    end;
end $$;
rollback;
