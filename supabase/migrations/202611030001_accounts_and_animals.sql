-- Run once in a development Supabase project's SQL editor, as its database owner.
-- Atomic: an incompatible pre-existing schema or unknown policy aborts the migration.
begin;

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    name text not null default '',
    email text not null default ''
);
alter table public.profiles add column if not exists name text not null default '';
alter table public.profiles add column if not exists email text not null default '';

create table if not exists public.animals (
    id uuid primary key,
    owner_id uuid not null references auth.users(id) on delete cascade,
    name text not null check (length(btrim(name)) > 0),
    species text not null check (species in ('Cow', 'Chicken', 'Pig')),
    breed text not null check (length(btrim(breed)) > 0),
    weight integer not null check (weight > 0),
    feed_type text not null check (length(btrim(feed_type)) > 0),
    feed_schedule integer not null check (feed_schedule > 0),
    vaccination_type text not null check (length(btrim(vaccination_type)) > 0),
    vaccination_frequency integer not null check (vaccination_frequency in (1,2,3,4,6,8,12,24)),
    last_vaccination_date timestamptz not null,
    notes text not null default '',
    deleted_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);
create index if not exists animals_owner_id_idx on public.animals(owner_id);

-- Existing permissive policies would combine with these using OR. Do not silently keep them.
do $$
begin
    if exists (
        select 1 from pg_policies
        where schemaname = 'public' and tablename in ('profiles', 'animals')
        and policyname not in ('profiles_read_own', 'profiles_update_own',
                              'animals_read_own', 'animals_insert_own', 'animals_update_own')
    ) then
        raise exception 'Existing profiles/animals access policies need review before applying this migration.';
    end if;
end $$;

alter table public.profiles enable row level security;
alter table public.animals enable row level security;

revoke all on public.profiles, public.animals from public, anon, authenticated;
grant select on public.profiles to authenticated;
grant update (name) on public.profiles to authenticated;
grant select, insert, update on public.animals to authenticated;

drop policy if exists profiles_read_own on public.profiles;
create policy profiles_read_own on public.profiles for select to authenticated
    using ((select auth.uid()) = id);
drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles for update to authenticated
    using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
drop policy if exists animals_read_own on public.animals;
create policy animals_read_own on public.animals for select to authenticated
    using ((select auth.uid()) = owner_id);
drop policy if exists animals_insert_own on public.animals;
create policy animals_insert_own on public.animals for insert to authenticated
    with check ((select auth.uid()) = owner_id);
drop policy if exists animals_update_own on public.animals;
create policy animals_update_own on public.animals for update to authenticated
    using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);

create or replace function public.farmcare_create_profile()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
    insert into public.profiles (id, name, email)
    values (new.id, coalesce(new.raw_user_meta_data ->> 'name', ''), coalesce(new.email, ''))
    on conflict (id) do update set email = excluded.email;
    return new;
end;
$$;
revoke all on function public.farmcare_create_profile() from public, anon, authenticated;
drop trigger if exists farmcare_create_profile on auth.users;
create trigger farmcare_create_profile after insert or update of email on auth.users
    for each row execute function public.farmcare_create_profile();

-- Backfill accounts created before this migration.
insert into public.profiles (id, name, email)
select id, coalesce(raw_user_meta_data ->> 'name', ''), coalesce(email, '') from auth.users
on conflict (id) do update set email = excluded.email;

create or replace function public.farmcare_update_animal()
returns trigger language plpgsql set search_path = '' as $$
begin
    -- A stale offline device cannot resurrect an animal deleted on another device.
    if old.deleted_at is not null then return old; end if;
    new.created_at = old.created_at;
    new.updated_at = now();
    return new;
end;
$$;
revoke all on function public.farmcare_update_animal() from public, anon, authenticated;
drop trigger if exists farmcare_update_animal on public.animals;
create trigger farmcare_update_animal before update on public.animals
    for each row execute function public.farmcare_update_animal();

commit;
