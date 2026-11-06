from concurrent.futures import ThreadPoolExecutor
from uuid import uuid4


def mutation(record_id=None, base=0, operation="upsert", name="Bessie"):
    return {"mutation_id": str(uuid4()), "record_id": record_id or str(uuid4()), "base_revision": base,
            "operation": operation, **({"data": {"name": name, "species": "Cow", "breed": "Jersey", "weight": 450,
            "feed_type": "Grass", "feed_schedule": 2, "vaccination_type": "Routine", "vaccination_frequency": 4,
            "last_vaccination_date": "2026-11-06T10:00:00Z", "notes": "Healthy"}} if operation == "upsert" else {})}


def push(client, headers, *changes):
    return client.post("/v1/sync/push", headers=headers, json={"mutations": list(changes)})


def test_accounts_cannot_read_write_or_delete_each_others_animals(client, account):
    _, first = account()
    _, second = account()
    change = mutation()
    assert push(client, first, change).status_code == 200
    assert client.get("/v1/animals", headers=second).json() == {"animals": []}
    assert client.get("/v1/sync/pull", headers=second).json()["changes"] == []
    assert client.get("/v1/animals/" + change["record_id"], headers=second).status_code == 404
    for op in ("upsert", "delete"):
        assert push(client, second, mutation(change["record_id"], base=1, operation=op)).status_code == 404
    assert client.get("/v1/animals/" + change["record_id"], headers=first).json()["revision"] == 1


def test_idempotent_push_and_payload_reuse_detection(client, account):
    _, headers = account()
    change = mutation()
    first = push(client, headers, change)
    assert first.status_code == 200
    assert push(client, headers, change).json() == first.json()
    assert len(client.get("/v1/sync/pull", headers=headers).json()["changes"]) == 1
    change["data"]["name"] = "Other"
    assert push(client, headers, change).status_code == 409


def test_revision_conflict_preserves_server_version(client, account):
    _, headers = account()
    initial = mutation()
    push(client, headers, initial)
    assert push(client, headers, mutation(initial["record_id"], 1, name="New name")).json()["results"][0]["status"] == "applied"
    stale = push(client, headers, mutation(initial["record_id"], 1, name="Stale edit")).json()["results"][0]
    assert stale["status"] == "conflict"
    assert stale["record"]["data"]["name"] == "New name"
    assert stale["record"]["revision"] == 2


def test_tombstones_prevent_resurrection_and_are_pulled(client, account):
    _, headers = account()
    initial = mutation()
    push(client, headers, initial)
    response = push(client, headers, mutation(initial["record_id"], 1, "delete"))
    assert response.json()["results"][0]["record"]["deleted"] is True
    stale = push(client, headers, mutation(initial["record_id"], 1)).json()["results"][0]
    assert stale["status"] == "deleted"
    assert client.get("/v1/animals", headers=headers).json()["animals"] == []
    assert client.get("/v1/sync/pull", headers=headers).json()["changes"][-1]["deleted"] is True


def test_cursor_snapshot_pagination_and_later_changes(client, account):
    _, headers = account()
    initial = [mutation() for _ in range(3)]
    assert push(client, headers, *initial).status_code == 200
    first = client.get("/v1/sync/pull?limit=1", headers=headers).json()
    assert first["has_more"]
    assert push(client, headers, mutation(initial[1]["record_id"], 2, name="After snapshot")).status_code == 200
    second = client.get("/v1/sync/pull", params={"limit": 1, "cursor": first["cursor"]}, headers=headers).json()
    assert second["changes"][0]["data"]["name"] == "Bessie"
    third = client.get("/v1/sync/pull", params={"limit": 1, "cursor": second["cursor"]}, headers=headers).json()
    assert not third["has_more"]
    next_page = client.get("/v1/sync/pull", params={"cursor": third["cursor"]}, headers=headers).json()
    assert len(next_page["changes"]) == 1
    assert next_page["changes"][0]["data"]["name"] == "After snapshot"


def test_cursor_is_account_bound_and_tamper_proof(client, account):
    _, a = account()
    _, b = account()
    cursor = client.get("/v1/sync/pull", headers=a).json()["cursor"]
    assert client.get("/v1/sync/pull", params={"cursor": cursor}, headers=b).status_code == 400
    assert client.get("/v1/sync/pull", params={"cursor": cursor + "broken"}, headers=a).status_code == 400


def test_batch_rollback_and_owner_input_rejection(client, account):
    _, a = account()
    _, b = account()
    private = mutation()
    push(client, b, private)
    assert push(client, a, mutation(), mutation(private["record_id"], 1)).status_code == 404
    assert client.get("/v1/animals", headers=a).json()["animals"] == []
    injected = mutation()
    injected["data"]["owner_id"] = str(uuid4())
    assert push(client, a, injected).status_code == 422


def test_concurrent_creates_allocate_ordered_unique_revisions(client, account):
    _, headers = account()
    changes = [mutation() for _ in range(4)]
    with ThreadPoolExecutor(max_workers=4) as pool:
        responses = list(pool.map(lambda m: push(client, headers, m), changes))
    assert all(r.status_code == 200 for r in responses)
    pulled = client.get("/v1/sync/pull", headers=headers).json()["changes"]
    assert [r["revision"] for r in pulled] == [1, 2, 3, 4]


def test_unauthenticated_and_invalid_writes_fail(client, account):
    assert client.get("/v1/animals").status_code == 401
    assert push(client, {}, mutation()).status_code == 401
    _, headers = account()
    invalid = mutation()
    invalid["data"]["weight"] = -1
    assert push(client, headers, invalid).status_code == 422
    assert push(client, headers, *[mutation() for _ in range(101)]).status_code == 422
