#!/usr/bin/env python3
"""Stable happy-path smoke runner for identity -> project -> ingest -> cleanup."""

from __future__ import annotations

import sys

from e2e_common import (
    DEFAULT_IDENTITY_BASE_URL,
    DEFAULT_INGEST_BASE_URL,
    DEFAULT_PROJECT_BASE_URL,
    E2EError,
    HttpClient,
    ensure_services_healthy,
    extract_data,
    format_body,
    load_token,
    make_name,
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise E2EError(message)


def cleanup_step(
    client: HttpClient,
    results: list[str],
    *,
    step: str,
    method: str,
    url: str,
) -> None:
    status, body = client.request(
        step=step,
        method=method,
        url=url,
        expected_status=200,
        fatal=False,
    )
    if status == 200:
        results.append(f"OK   {step}")
    else:
        results.append(f"FAIL {step}: status={status}, body={format_body(body)}")


def find_item_by_id(items: list[dict[str, object]], item_id: str) -> dict[str, object] | None:
    for item in items:
        if item.get("id") == item_id:
            return item
    return None


def main() -> int:
    token = load_token()
    client = HttpClient(token)

    identity_base = DEFAULT_IDENTITY_BASE_URL.rstrip("/")
    project_base = DEFAULT_PROJECT_BASE_URL.rstrip("/")
    ingest_base = DEFAULT_INGEST_BASE_URL.rstrip("/")

    project_api = f"{project_base}/api/v1"
    ingest_api = f"{ingest_base}/api/v1"
    identity_api = f"{identity_base}/authentication"

    state: dict[str, str | None] = {
        "campaign_id": None,
        "project_id": None,
        "datasource_id": None,
        "keyword_target_id": None,
        "profile_target_id": None,
        "post_target_id": None,
    }
    cleanup_results: list[str] = []

    print("Local E2E starting")
    print(f"- identity: {identity_base}")
    print(f"- project:  {project_base}")
    print(f"- ingest:   {ingest_base}")

    try:
        print("")
        print("[health] service preflight")
        ensure_services_healthy(identity_base, project_base, ingest_base)

        print("")
        print("[smoke] identity /authentication/me")
        status, body = client.request(
            step="identity me",
            method="GET",
            url=f"{identity_api}/me",
            expected_status=200,
            fatal=False,
        )
        if status == 200:
            print(f"  OK  identity /me -> {format_body(body)}")
        else:
            print(f"  SKIP identity /me -> status={status}, body={format_body(body)}")

        campaign_payload = {
            "name": make_name("campaign"),
            "description": "E2E campaign created by test/happy_path_e2e.py",
            "start_date": "2026-01-01T00:00:00Z",
            "end_date": "2026-12-31T23:59:59Z",
        }
        print("")
        print("[create] campaign")
        _, body = client.request(
            step="create campaign",
            method="POST",
            url=f"{project_api}/campaigns",
            json_body=campaign_payload,
        )
        state["campaign_id"] = extract_data(body)["campaign"]["id"]
        print(f"  campaign_id={state['campaign_id']}")

        print("[read] campaign detail")
        _, body = client.request(
            step="campaign detail",
            method="GET",
            url=f"{project_api}/campaigns/{state['campaign_id']}",
        )
        campaign_detail = extract_data(body)["campaign"]
        require(
            campaign_detail["name"] == campaign_payload["name"],
            "campaign detail name mismatch after create",
        )

        print("[read] campaign list")
        _, body = client.request(
            step="campaign list",
            method="GET",
            url=f"{project_api}/campaigns?page=1&limit=100",
        )
        campaigns = extract_data(body)["campaigns"]
        require(
            find_item_by_id(campaigns, state["campaign_id"]) is not None,
            "campaign not found in campaign list",
        )

        campaign_update_payload = {
            "name": f"{campaign_payload['name']}_updated",
            "description": "E2E campaign updated by happy_path_e2e.py",
            "status": "INACTIVE",
        }
        print("[update] campaign")
        _, body = client.request(
            step="campaign update",
            method="PUT",
            url=f"{project_api}/campaigns/{state['campaign_id']}",
            json_body=campaign_update_payload,
        )
        updated_campaign = extract_data(body)["campaign"]
        require(updated_campaign["name"] == campaign_update_payload["name"], "campaign update name mismatch")
        require(updated_campaign["status"] == campaign_update_payload["status"], "campaign update status mismatch")

        project_payload = {
            "name": make_name("project"),
            "description": "E2E project under campaign",
            "brand": "SMAP E2E",
            "entity_type": "product",
            "entity_name": "E2E Entity",
        }
        print("[create] project")
        _, body = client.request(
            step="create project",
            method="POST",
            url=f"{project_api}/campaigns/{state['campaign_id']}/projects",
            json_body=project_payload,
        )
        state["project_id"] = extract_data(body)["project"]["id"]
        print(f"  project_id={state['project_id']}")

        print("[read] project detail")
        _, body = client.request(
            step="project detail",
            method="GET",
            url=f"{project_api}/projects/{state['project_id']}",
        )
        project_detail = extract_data(body)["project"]
        require(project_detail["name"] == project_payload["name"], "project detail name mismatch after create")

        print("[read] project list")
        _, body = client.request(
            step="project list",
            method="GET",
            url=f"{project_api}/campaigns/{state['campaign_id']}/projects?page=1&limit=100",
        )
        projects = extract_data(body)["projects"]
        require(
            find_item_by_id(projects, state["project_id"]) is not None,
            "project not found in project list",
        )

        project_update_payload = {
            "name": f"{project_payload['name']}_updated",
            "description": "E2E project updated by happy_path_e2e.py",
            "brand": "SMAP E2E Updated",
            "entity_name": "E2E Entity Updated",
            "status": "PAUSED",
        }
        print("[update] project")
        _, body = client.request(
            step="project update",
            method="PUT",
            url=f"{project_api}/projects/{state['project_id']}",
            json_body=project_update_payload,
        )
        updated_project = extract_data(body)["project"]
        require(updated_project["name"] == project_update_payload["name"], "project update name mismatch")
        require(updated_project["status"] == project_update_payload["status"], "project update status mismatch")

        crisis_payload = {
            "keywords_trigger": {
                "enabled": True,
                "logic": "OR",
                "groups": [
                    {
                        "name": "E2E keywords",
                        "keywords": ["e2e alert", "e2e incident"],
                        "weight": 10,
                    }
                ],
            },
            "volume_trigger": {
                "enabled": True,
                "metric": "MENTIONS",
                "rules": [
                    {
                        "level": "CRITICAL",
                        "threshold_percent_growth": 150,
                        "comparison_window_hours": 1,
                        "baseline": "PREVIOUS_PERIOD",
                    }
                ],
            },
        }
        print("[upsert] crisis-config")
        client.request(
            step="upsert crisis config",
            method="PUT",
            url=f"{project_api}/projects/{state['project_id']}/crisis-config",
            json_body=crisis_payload,
        )

        print("[read] crisis-config detail")
        _, body = client.request(
            step="crisis detail",
            method="GET",
            url=f"{project_api}/projects/{state['project_id']}/crisis-config",
        )
        crisis_detail = extract_data(body)["crisis_config"]
        require(
            crisis_detail["keywords_trigger"]["groups"][0]["name"] == "E2E keywords",
            "crisis detail keywords trigger mismatch after first upsert",
        )

        crisis_update_payload = {
            "keywords_trigger": {
                "enabled": True,
                "logic": "AND",
                "groups": [
                    {
                        "name": "E2E keywords updated",
                        "keywords": ["e2e alert updated", "e2e incident updated"],
                        "weight": 11,
                    }
                ],
            }
        }
        print("[update] crisis-config")
        client.request(
            step="crisis update",
            method="PUT",
            url=f"{project_api}/projects/{state['project_id']}/crisis-config",
            json_body=crisis_update_payload,
        )
        _, body = client.request(
            step="crisis detail after update",
            method="GET",
            url=f"{project_api}/projects/{state['project_id']}/crisis-config",
        )
        crisis_detail = extract_data(body)["crisis_config"]
        require(
            crisis_detail["keywords_trigger"]["groups"][0]["name"] == "E2E keywords updated",
            "crisis update detail mismatch",
        )

        datasource_payload = {
            "project_id": state["project_id"],
            "name": make_name("datasource"),
            "description": "E2E datasource for target creation",
            "source_type": "TIKTOK",
            "source_category": "CRAWL",
            "crawl_mode": "NORMAL",
            "crawl_interval_minutes": 11,
        }
        print("[create] datasource")
        _, body = client.request(
            step="create datasource",
            method="POST",
            url=f"{ingest_api}/datasources",
            json_body=datasource_payload,
        )
        state["datasource_id"] = extract_data(body)["data_source"]["id"]
        print(f"  datasource_id={state['datasource_id']}")

        print("[read] datasource detail")
        _, body = client.request(
            step="datasource detail",
            method="GET",
            url=f"{ingest_api}/datasources/{state['datasource_id']}",
        )
        datasource_detail = extract_data(body)["data_source"]
        require(
            datasource_detail["name"] == datasource_payload["name"],
            "datasource detail name mismatch after create",
        )

        print("[read] datasource list")
        _, body = client.request(
            step="datasource list",
            method="GET",
            url=f"{ingest_api}/datasources?project_id={state['project_id']}&page=1&limit=100",
        )
        datasources = extract_data(body)["data_sources"]
        require(
            find_item_by_id(datasources, state["datasource_id"]) is not None,
            "datasource not found in datasource list",
        )

        datasource_update_payload = {
            "name": f"{datasource_payload['name']}_updated",
            "description": "E2E datasource updated by happy_path_e2e.py",
        }
        print("[update] datasource")
        _, body = client.request(
            step="datasource update",
            method="PUT",
            url=f"{ingest_api}/datasources/{state['datasource_id']}",
            json_body=datasource_update_payload,
        )
        updated_datasource = extract_data(body)["data_source"]
        require(
            updated_datasource["name"] == datasource_update_payload["name"],
            "datasource update name mismatch",
        )

        keyword_target_payload = {
            "values": ["vinfast e2e keyword"],
            "label": "E2E keyword target",
            "is_active": True,
            "priority": 1,
            "crawl_interval_minutes": 11,
        }
        print("[create] keyword target")
        _, body = client.request(
            step="create keyword target",
            method="POST",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/keywords",
            json_body=keyword_target_payload,
        )
        state["keyword_target_id"] = extract_data(body)["target"]["id"]
        print(f"  keyword_target_id={state['keyword_target_id']}")

        print("[read] keyword target detail")
        _, body = client.request(
            step="keyword target detail",
            method="GET",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['keyword_target_id']}",
        )
        keyword_target = extract_data(body)["target"]
        require(keyword_target["target_type"] == "KEYWORD", "keyword target type mismatch")

        keyword_target_update_payload = {
            "values": ["vinfast e2e keyword updated"],
            "label": "E2E keyword target updated",
            "is_active": True,
            "priority": 2,
            "crawl_interval_minutes": 12,
        }
        print("[update] keyword target")
        _, body = client.request(
            step="keyword target update",
            method="PUT",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['keyword_target_id']}",
            json_body=keyword_target_update_payload,
        )
        updated_keyword_target = extract_data(body)["target"]
        require(
            updated_keyword_target["values"][0] == keyword_target_update_payload["values"][0],
            "keyword target update values mismatch",
        )

        profile_target_payload = {
            "values": ["https://www.tiktok.com/@vinfastauto_official"],
            "label": "E2E profile target",
            "is_active": True,
            "priority": 1,
            "crawl_interval_minutes": 11,
        }
        print("[create] profile target")
        _, body = client.request(
            step="create profile target",
            method="POST",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/profiles",
            json_body=profile_target_payload,
        )
        state["profile_target_id"] = extract_data(body)["target"]["id"]
        print(f"  profile_target_id={state['profile_target_id']}")

        print("[read] profile target detail")
        _, body = client.request(
            step="profile target detail",
            method="GET",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['profile_target_id']}",
        )
        profile_target = extract_data(body)["target"]
        require(profile_target["target_type"] == "PROFILE", "profile target type mismatch")

        profile_target_update_payload = {
            "label": "E2E profile target updated",
            "priority": 2,
            "crawl_interval_minutes": 12,
        }
        print("[update] profile target")
        _, body = client.request(
            step="profile target update",
            method="PUT",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['profile_target_id']}",
            json_body=profile_target_update_payload,
        )
        updated_profile_target = extract_data(body)["target"]
        require(
            updated_profile_target["label"] == profile_target_update_payload["label"],
            "profile target update label mismatch",
        )

        post_target_payload = {
            "values": [
                "https://www.tiktok.com/@vinfastauto_official/video/7481234567890123456"
            ],
            "label": "E2E post target",
            "is_active": True,
            "priority": 1,
            "crawl_interval_minutes": 11,
        }
        print("[create] post target")
        _, body = client.request(
            step="create post target",
            method="POST",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/posts",
            json_body=post_target_payload,
        )
        state["post_target_id"] = extract_data(body)["target"]["id"]
        print(f"  post_target_id={state['post_target_id']}")

        print("[read] post target detail")
        _, body = client.request(
            step="post target detail",
            method="GET",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['post_target_id']}",
        )
        post_target = extract_data(body)["target"]
        require(post_target["target_type"] == "POST_URL", "post target type mismatch")

        post_target_update_payload = {
            "label": "E2E post target updated",
            "priority": 2,
            "crawl_interval_minutes": 12,
        }
        print("[update] post target")
        _, body = client.request(
            step="post target update",
            method="PUT",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['post_target_id']}",
            json_body=post_target_update_payload,
        )
        updated_post_target = extract_data(body)["target"]
        require(
            updated_post_target["label"] == post_target_update_payload["label"],
            "post target update label mismatch",
        )

        print("[read] target list")
        _, body = client.request(
            step="target list",
            method="GET",
            url=f"{ingest_api}/datasources/{state['datasource_id']}/targets",
        )
        targets = extract_data(body)["targets"]
        require(
            find_item_by_id(targets, state["keyword_target_id"]) is not None,
            "keyword target not found in target list",
        )
        require(
            find_item_by_id(targets, state["profile_target_id"]) is not None,
            "profile target not found in target list",
        )
        require(
            find_item_by_id(targets, state["post_target_id"]) is not None,
            "post target not found in target list",
        )

        print("")
        print("E2E CRUD flow completed successfully.")
        return_code = 0

    except E2EError as exc:
        print("")
        print(f"E2E failed: {exc}", file=sys.stderr)
        return_code = 1

    finally:
        print("")
        print("Cleanup starting")
        if state["post_target_id"] and state["datasource_id"]:
            cleanup_step(
                client,
                cleanup_results,
                step="delete post target",
                method="DELETE",
                url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['post_target_id']}",
            )
        if state["profile_target_id"] and state["datasource_id"]:
            cleanup_step(
                client,
                cleanup_results,
                step="delete profile target",
                method="DELETE",
                url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['profile_target_id']}",
            )
        if state["keyword_target_id"] and state["datasource_id"]:
            cleanup_step(
                client,
                cleanup_results,
                step="delete keyword target",
                method="DELETE",
                url=f"{ingest_api}/datasources/{state['datasource_id']}/targets/{state['keyword_target_id']}",
            )
        if state["datasource_id"]:
            cleanup_step(
                client,
                cleanup_results,
                step="archive datasource",
                method="DELETE",
                url=f"{ingest_api}/datasources/{state['datasource_id']}",
            )
        if state["project_id"]:
            cleanup_step(
                client,
                cleanup_results,
                step="delete crisis-config",
                method="DELETE",
                url=f"{project_api}/projects/{state['project_id']}/crisis-config",
            )
            cleanup_step(
                client,
                cleanup_results,
                step="archive project",
                method="DELETE",
                url=f"{project_api}/projects/{state['project_id']}",
            )
        if state["campaign_id"]:
            cleanup_step(
                client,
                cleanup_results,
                step="archive campaign",
                method="DELETE",
                url=f"{project_api}/campaigns/{state['campaign_id']}",
            )

        print("Cleanup summary:")
        for line in cleanup_results:
            print(f"- {line}")

    return return_code


if __name__ == "__main__":
    raise SystemExit(main())
