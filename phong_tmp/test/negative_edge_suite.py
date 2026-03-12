#!/usr/bin/env python3
"""Negative and edge-case E2E suite for identity -> project -> ingest."""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any

from e2e_common import (
    ArtifactStore,
    DEFAULT_IDENTITY_BASE_URL,
    DEFAULT_INGEST_BASE_URL,
    DEFAULT_PROJECT_BASE_URL,
    E2EError,
    HttpClient,
    build_negative_tokens,
    effective_status,
    ensure_services_healthy,
    extract_data,
    format_body,
    load_token,
    make_name,
)


class SuiteRunner:
    def __init__(self) -> None:
        self.artifacts = ArtifactStore("negative_edge_suite")
        self.passed = 0
        self.failed = 0
        self.skipped = 0
        self.failures: list[str] = []
        self.cleanup_notes: list[str] = []

    def _write_failure(
        self,
        *,
        case_id: str,
        name: str,
        method: str,
        url: str,
        payload: dict[str, Any] | None,
        expected_status: int | tuple[int, ...],
        actual_status: int,
        raw_status: int,
        response_body: Any,
    ) -> Path:
        return self.artifacts.write_failure(
            case_id,
            {
                "case_id": case_id,
                "name": name,
                "request": {
                    "method": method,
                    "url": url,
                    "payload": payload,
                },
                "expected_status": expected_status,
                "raw_http_status": raw_status,
                "actual_status": actual_status,
                "response_body": response_body,
            },
        )

    def run_case(
        self,
        *,
        case_id: str,
        name: str,
        client: HttpClient,
        method: str,
        url: str,
        expected_status: int | tuple[int, ...],
        payload: dict[str, Any] | None = None,
    ) -> tuple[int, Any]:
        print(f"[{case_id}] {name}")
        try:
            raw_status, body = client.request(
                step=case_id,
                method=method,
                url=url,
                json_body=payload,
                expected_status=expected_status,
                fatal=False,
            )
        except E2EError as exc:
            raw_status, body = 0, {"request_error": str(exc)}

        status = effective_status(raw_status, body)

        expected_tuple = (
            expected_status if isinstance(expected_status, tuple) else (expected_status,)
        )
        if status in expected_tuple:
            self.passed += 1
            print(f"  PASS status={status} raw={raw_status}")
            return status, body

        self.failed += 1
        artifact_path = self._write_failure(
            case_id=case_id,
            name=name,
            method=method,
            url=url,
            payload=payload,
            expected_status=expected_status,
            actual_status=status,
            raw_status=raw_status,
            response_body=body,
        )
        summary = (
            f"{case_id} expected {expected_tuple}, got {status} raw={raw_status}, artifact={artifact_path}"
        )
        self.failures.append(summary)
        print(f"  FAIL expected={expected_tuple} got={status} raw={raw_status}")
        print(f"  body={format_body(body)}")
        return status, body

    def skip(self, case_id: str, reason: str) -> None:
        self.skipped += 1
        print(f"[{case_id}] SKIP {reason}")

    def cleanup_call(
        self,
        *,
        client: HttpClient,
        label: str,
        method: str,
        url: str,
        expected_status: int | tuple[int, ...] = (200, 400, 404),
    ) -> None:
        raw_status, body = client.request(
            step=label,
            method=method,
            url=url,
            expected_status=expected_status,
            fatal=False,
        )
        status = effective_status(raw_status, body)
        self.cleanup_notes.append(
            f"{label}: status={status}, raw={raw_status}, body={format_body(body)}"
        )

    def print_summary(self) -> int:
        print("")
        print("Summary")
        print(f"- passed: {self.passed}")
        print(f"- failed: {self.failed}")
        print(f"- skipped: {self.skipped}")
        if self.failures:
            print("- failures:")
            for line in self.failures:
                print(f"  {line}")
        if self.cleanup_notes:
            print("- cleanup:")
            for line in self.cleanup_notes:
                print(f"  {line}")
        if self.artifacts.created:
            print(f"- failure_artifacts: {self.artifacts.base_dir}")
        return 1 if self.failed else 0


def create_campaign(client: HttpClient, project_api: str, name: str) -> str:
    _, body = client.request(
        step="setup create campaign",
        method="POST",
        url=f"{project_api}/campaigns",
        json_body={"name": name},
    )
    return extract_data(body)["campaign"]["id"]


def create_project(
    client: HttpClient, project_api: str, campaign_id: str, name: str
) -> str:
    _, body = client.request(
        step="setup create project",
        method="POST",
        url=f"{project_api}/campaigns/{campaign_id}/projects",
        json_body={
            "name": name,
            "entity_type": "product",
            "entity_name": f"{name}-entity",
        },
    )
    return extract_data(body)["project"]["id"]


def create_datasource(
    client: HttpClient, ingest_api: str, project_id: str, name: str
) -> str:
    _, body = client.request(
        step="setup create datasource",
        method="POST",
        url=f"{ingest_api}/datasources",
        json_body={
            "project_id": project_id,
            "name": name,
            "source_type": "TIKTOK",
            "source_category": "CRAWL",
            "crawl_mode": "NORMAL",
            "crawl_interval_minutes": 11,
        },
    )
    return extract_data(body)["data_source"]["id"]


def create_target(
    client: HttpClient,
    ingest_api: str,
    datasource_id: str,
    target_kind: str,
    values: list[str],
    label: str,
) -> str:
    _, body = client.request(
        step=f"setup create {target_kind} target",
        method="POST",
        url=f"{ingest_api}/datasources/{datasource_id}/targets/{target_kind}",
        json_body={
            "values": values,
            "label": label,
            "is_active": True,
            "priority": 1,
            "crawl_interval_minutes": 11,
        },
    )
    return extract_data(body)["target"]["id"]


def main() -> int:
    identity_base = DEFAULT_IDENTITY_BASE_URL.rstrip("/")
    project_base = DEFAULT_PROJECT_BASE_URL.rstrip("/")
    ingest_base = DEFAULT_INGEST_BASE_URL.rstrip("/")
    project_api = f"{project_base}/api/v1"
    ingest_api = f"{ingest_base}/api/v1"
    identity_api = f"{identity_base}/authentication"

    print("Negative/edge suite starting")
    print(f"- identity: {identity_base}")
    print(f"- project:  {project_base}")
    print(f"- ingest:   {ingest_base}")
    print("")
    print("[health] service preflight")
    ensure_services_healthy(identity_base, project_base, ingest_base)

    real_token = load_token()
    tokens = build_negative_tokens(real_token)
    real_client = HttpClient(tokens["valid"])
    project_clients = {
        key: HttpClient(value or None)
        for key, value in tokens.items()
    }
    ingest_valid_client = HttpClient(tokens["valid"])
    runner = SuiteRunner()

    created_campaign_ids: list[str] = []
    created_project_ids: list[str] = []
    created_datasource_ids: list[str] = []
    created_target_refs: list[tuple[str, str]] = []

    setup_campaign_id: str | None = None
    setup_project_id: str | None = None
    setup_datasource_id: str | None = None
    setup_keyword_target_id: str | None = None

    try:
        print("")
        print("[auth]")
        runner.run_case(
            case_id="AUTH-01",
            name="Project without token",
            client=project_clients["missing"],
            method="GET",
            url=f"{project_api}/campaigns",
            expected_status=401,
        )
        runner.run_case(
            case_id="AUTH-02",
            name="Project malformed token",
            client=project_clients["malformed"],
            method="GET",
            url=f"{project_api}/campaigns",
            expected_status=401,
        )
        runner.run_case(
            case_id="AUTH-03",
            name="Project invalid signature",
            client=project_clients["invalid_signature"],
            method="GET",
            url=f"{project_api}/campaigns",
            expected_status=401,
        )
        runner.run_case(
            case_id="AUTH-04",
            name="Project expired token",
            client=project_clients["expired"],
            method="GET",
            url=f"{project_api}/campaigns",
            expected_status=401,
        )
        runner.run_case(
            case_id="AUTH-05",
            name="Identity token works on project list",
            client=project_clients["valid"],
            method="GET",
            url=f"{project_api}/campaigns",
            expected_status=200,
        )
        runner.run_case(
            case_id="AUTH-06",
            name="Identity token works on ingest list",
            client=ingest_valid_client,
            method="GET",
            url=f"{ingest_api}/datasources",
            expected_status=200,
        )
        runner.run_case(
            case_id="AUTH-07",
            name="Identity me returns current user",
            client=real_client,
            method="GET",
            url=f"{identity_api}/me",
            expected_status=200,
        )

        print("")
        print("[campaign/project setup]")
        try:
            setup_campaign_id = create_campaign(real_client, project_api, make_name("neg_campaign"))
            created_campaign_ids.append(setup_campaign_id)
            setup_project_id = create_project(
                real_client,
                project_api,
                setup_campaign_id,
                make_name("neg_project"),
            )
            created_project_ids.append(setup_project_id)
        except E2EError as exc:
            print(f"Setup failed: {exc}", file=sys.stderr)

        print("")
        print("[campaign]")
        runner.run_case(
            case_id="CAM-01",
            name="Campaign missing name",
            client=real_client,
            method="POST",
            url=f"{project_api}/campaigns",
            expected_status=400,
            payload={"description": "missing name"},
        )
        runner.run_case(
            case_id="CAM-02",
            name="Campaign empty name",
            client=real_client,
            method="POST",
            url=f"{project_api}/campaigns",
            expected_status=400,
            payload={"name": ""},
        )
        runner.run_case(
            case_id="CAM-03",
            name="Campaign bad RFC3339",
            client=real_client,
            method="POST",
            url=f"{project_api}/campaigns",
            expected_status=400,
            payload={
                "name": "BadDate",
                "start_date": "2026-01-01",
                "end_date": "not-a-date",
            },
        )
        runner.run_case(
            case_id="CAM-04",
            name="Campaign invalid date range",
            client=real_client,
            method="POST",
            url=f"{project_api}/campaigns",
            expected_status=400,
            payload={
                "name": "BadRange",
                "start_date": "2026-12-01T00:00:00Z",
                "end_date": "2026-01-01T00:00:00Z",
            },
        )
        if setup_campaign_id:
            runner.run_case(
                case_id="CAM-05",
                name="Campaign invalid status update",
                client=real_client,
                method="PUT",
                url=f"{project_api}/campaigns/{setup_campaign_id}",
                expected_status=400,
                payload={"status": "BANANA"},
            )
            runner.run_case(
                case_id="CAM-06",
                name="Campaign detail invalid UUID",
                client=real_client,
                method="GET",
                url=f"{project_api}/campaigns/not-a-uuid",
                expected_status=400,
            )
            runner.run_case(
                case_id="CAM-07",
                name="Campaign detail not found",
                client=real_client,
                method="GET",
                url=f"{project_api}/campaigns/{uuid_like('deadbeef')}",
                expected_status=500,
            )
        else:
            runner.skip("CAM-05..07", "campaign setup unavailable")

        print("")
        print("[project]")
        if setup_campaign_id and setup_project_id:
            runner.run_case(
                case_id="PROJ-01",
                name="Project missing entity_type",
                client=real_client,
                method="POST",
                url=f"{project_api}/campaigns/{setup_campaign_id}/projects",
                expected_status=400,
                payload={"name": "Bad Project", "entity_name": "Entity"},
            )
            runner.run_case(
                case_id="PROJ-02",
                name="Project missing entity_name",
                client=real_client,
                method="POST",
                url=f"{project_api}/campaigns/{setup_campaign_id}/projects",
                expected_status=400,
                payload={"name": "Bad Project", "entity_type": "product"},
            )
            runner.run_case(
                case_id="PROJ-03",
                name="Project empty name",
                client=real_client,
                method="POST",
                url=f"{project_api}/campaigns/{setup_campaign_id}/projects",
                expected_status=400,
                payload={
                    "name": "",
                    "entity_type": "product",
                    "entity_name": "Entity",
                },
            )
            runner.run_case(
                case_id="PROJ-04",
                name="Project invalid entity_type",
                client=real_client,
                method="POST",
                url=f"{project_api}/campaigns/{setup_campaign_id}/projects",
                expected_status=400,
                payload={
                    "name": "Bad Project",
                    "entity_type": "banana",
                    "entity_name": "Entity",
                },
            )
            runner.run_case(
                case_id="PROJ-05",
                name="Project invalid status update",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}",
                expected_status=400,
                payload={"status": "INVALID_STATUS"},
            )
            runner.run_case(
                case_id="PROJ-06",
                name="Project invalid entity_type update",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}",
                expected_status=400,
                payload={"entity_type": "spaceship"},
            )

            archived_campaign_id = create_campaign(
                real_client, project_api, make_name("archived_campaign")
            )
            created_campaign_ids.append(archived_campaign_id)
            runner.cleanup_call(
                client=real_client,
                label="archive setup archived campaign",
                method="DELETE",
                url=f"{project_api}/campaigns/{archived_campaign_id}",
                expected_status=200,
            )
            runner.run_case(
                case_id="PROJ-07",
                name="Create project under archived campaign",
                client=real_client,
                method="POST",
                url=f"{project_api}/campaigns/{archived_campaign_id}/projects",
                expected_status=500,
                payload={
                    "name": "Archived Campaign Project",
                    "entity_type": "product",
                    "entity_name": "Entity",
                },
            )
            runner.run_case(
                case_id="PROJ-08",
                name="Project detail invalid UUID",
                client=real_client,
                method="GET",
                url=f"{project_api}/projects/not-a-uuid",
                expected_status=400,
            )
        else:
            runner.skip("PROJ", "project setup unavailable")

        print("")
        print("[crisis]")
        if setup_project_id:
            runner.run_case(
                case_id="CRI-01",
                name="Crisis keywords-only upsert",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=200,
                payload={
                    "keywords_trigger": {
                        "enabled": True,
                        "logic": "OR",
                        "groups": [
                            {"name": "Group", "keywords": ["bug"], "weight": 1}
                        ],
                    }
                },
            )
            runner.run_case(
                case_id="CRI-02",
                name="Crisis all-trigger upsert",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=200,
                payload={
                    "keywords_trigger": {
                        "enabled": True,
                        "logic": "AND",
                        "groups": [
                            {"name": "All", "keywords": ["alert"], "weight": 1}
                        ],
                    },
                    "volume_trigger": {
                        "enabled": True,
                        "metric": "MENTIONS",
                        "rules": [
                            {
                                "level": "WARNING",
                                "threshold_percent_growth": 100,
                                "comparison_window_hours": 1,
                                "baseline": "PREVIOUS_PERIOD",
                            }
                        ],
                    },
                },
            )
            runner.run_case(
                case_id="CRI-03",
                name="Crisis empty body",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=400,
                payload={},
            )
            runner.run_case(
                case_id="CRI-04",
                name="Crisis invalid keyword group",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=400,
                payload={
                    "keywords_trigger": {
                        "enabled": True,
                        "logic": "OR",
                        "groups": [{"name": "", "keywords": [], "weight": 0}],
                    }
                },
            )
            runner.run_case(
                case_id="CRI-05",
                name="Crisis volume rules required",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=400,
                payload={
                    "volume_trigger": {
                        "enabled": True,
                        "metric": "MENTIONS",
                        "rules": [],
                    }
                },
            )
            runner.run_case(
                case_id="CRI-06",
                name="Crisis sentiment type required",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=400,
                payload={
                    "sentiment_trigger": {
                        "enabled": True,
                        "min_sample_size": 10,
                        "rules": [{"type": ""}],
                    }
                },
            )
            runner.run_case(
                case_id="CRI-07",
                name="Crisis influencer rules required",
                client=real_client,
                method="PUT",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=400,
                payload={
                    "influencer_trigger": {
                        "enabled": True,
                        "logic": "OR",
                        "rules": [],
                    }
                },
            )
            runner.run_case(
                case_id="CRI-08",
                name="Crisis delete config",
                client=real_client,
                method="DELETE",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=200,
            )
            runner.run_case(
                case_id="CRI-09",
                name="Crisis get after delete",
                client=real_client,
                method="GET",
                url=f"{project_api}/projects/{setup_project_id}/crisis-config",
                expected_status=500,
            )
        else:
            runner.skip("CRI", "project setup unavailable")

        print("")
        print("[datasource/targets setup]")
        if setup_project_id:
            try:
                setup_datasource_id = create_datasource(
                    real_client, ingest_api, setup_project_id, make_name("neg_datasource")
                )
                created_datasource_ids.append(setup_datasource_id)
                setup_keyword_target_id = create_target(
                    real_client,
                    ingest_api,
                    setup_datasource_id,
                    "keywords",
                    ["negative suite keyword"],
                    "negative suite keyword",
                )
                created_target_refs.append((setup_datasource_id, setup_keyword_target_id))
            except E2EError as exc:
                print(f"Datasource setup failed: {exc}", file=sys.stderr)

        print("")
        print("[datasource]")
        runner.run_case(
            case_id="DS-01",
            name="Datasource missing project_id",
            client=real_client,
            method="POST",
            url=f"{ingest_api}/datasources",
            expected_status=400,
            payload={"name": "Test DS", "source_type": "TIKTOK"},
        )
        runner.run_case(
            case_id="DS-02",
            name="Datasource missing name",
            client=real_client,
            method="POST",
            url=f"{ingest_api}/datasources",
            expected_status=400,
            payload={"project_id": "00000000-0000-0000-0000-000000000000", "source_type": "FACEBOOK"},
        )
        runner.run_case(
            case_id="DS-03",
            name="Datasource missing source_type",
            client=real_client,
            method="POST",
            url=f"{ingest_api}/datasources",
            expected_status=400,
            payload={"project_id": setup_project_id or "", "name": "Test"},
        )
        runner.run_case(
            case_id="DS-04",
            name="Datasource invalid source_type",
            client=real_client,
            method="POST",
            url=f"{ingest_api}/datasources",
            expected_status=400,
            payload={
                "project_id": setup_project_id or "",
                "name": "Test",
                "source_type": "INVALID",
            },
        )
        runner.run_case(
            case_id="DS-05",
            name="Datasource invalid source_category",
            client=real_client,
            method="POST",
            url=f"{ingest_api}/datasources",
            expected_status=400,
            payload={
                "project_id": setup_project_id or "",
                "name": "Test",
                "source_type": "TIKTOK",
                "source_category": "INVALID",
            },
        )
        runner.run_case(
            case_id="DS-06",
            name="Datasource invalid crawl_mode",
            client=real_client,
            method="POST",
            url=f"{ingest_api}/datasources",
            expected_status=400,
            payload={
                "project_id": setup_project_id or "",
                "name": "Test",
                "source_type": "TIKTOK",
                "source_category": "CRAWL",
                "crawl_mode": "INVALID",
                "crawl_interval_minutes": 11,
            },
        )
        runner.run_case(
            case_id="DS-07",
            name="Datasource negative crawl interval",
            client=real_client,
            method="POST",
            url=f"{ingest_api}/datasources",
            expected_status=400,
            payload={
                "project_id": setup_project_id or "",
                "name": "Test",
                "source_type": "TIKTOK",
                "source_category": "CRAWL",
                "crawl_mode": "NORMAL",
                "crawl_interval_minutes": -1,
            },
        )
        if setup_project_id:
            archived_project_id = create_project(
                real_client, project_api, setup_campaign_id or "", make_name("archived_project")
            )
            created_project_ids.append(archived_project_id)
            runner.cleanup_call(
                client=real_client,
                label="archive setup archived project",
                method="DELETE",
                url=f"{project_api}/projects/{archived_project_id}",
                expected_status=200,
            )
            status, body = runner.run_case(
                case_id="DS-08",
                name="Datasource under archived project",
                client=real_client,
                method="POST",
                url=f"{ingest_api}/datasources",
                expected_status=200,
                payload={
                    "project_id": archived_project_id,
                    "name": "Archived Project Datasource",
                    "source_type": "TIKTOK",
                    "source_category": "CRAWL",
                    "crawl_mode": "NORMAL",
                    "crawl_interval_minutes": 11,
                },
            )
            if status == 200:
                created_datasource_ids.append(extract_data(body)["data_source"]["id"])
        else:
            runner.skip("DS-08", "project setup unavailable")

        print("")
        print("[targets]")
        if setup_datasource_id and setup_keyword_target_id:
            runner.run_case(
                case_id="TGT-01",
                name="Target missing values",
                client=real_client,
                method="POST",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets/keywords",
                expected_status=400,
                payload={"is_active": True, "crawl_interval_minutes": 11},
            )
            runner.run_case(
                case_id="TGT-02",
                name="Target empty values",
                client=real_client,
                method="POST",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets/keywords",
                expected_status=400,
                payload={"values": [], "crawl_interval_minutes": 11},
            )
            runner.run_case(
                case_id="TGT-03",
                name="Profile target invalid URL",
                client=real_client,
                method="POST",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets/profiles",
                expected_status=400,
                payload={"values": ["bad-url"], "crawl_interval_minutes": 11},
            )
            runner.run_case(
                case_id="TGT-04",
                name="Post target invalid URL",
                client=real_client,
                method="POST",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets/posts",
                expected_status=400,
                payload={"values": ["also-bad"], "crawl_interval_minutes": 11},
            )
            runner.run_case(
                case_id="TGT-05",
                name="List targets invalid filter",
                client=real_client,
                method="GET",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets?target_type=INVALID",
                expected_status=400,
            )
            runner.run_case(
                case_id="TGT-06",
                name="Update target valid values",
                client=real_client,
                method="PUT",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets/{setup_keyword_target_id}",
                expected_status=200,
                payload={"values": ["updated negative suite keyword"]},
            )
            runner.run_case(
                case_id="TGT-07",
                name="Update target invalid interval",
                client=real_client,
                method="PUT",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets/{setup_keyword_target_id}",
                expected_status=400,
                payload={"crawl_interval_minutes": -5},
            )
            runner.run_case(
                case_id="TGT-08",
                name="Delete target once",
                client=real_client,
                method="DELETE",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets/{setup_keyword_target_id}",
                expected_status=200,
            )
            created_target_refs = [
                item for item in created_target_refs if item[1] != setup_keyword_target_id
            ]
            runner.run_case(
                case_id="TGT-09",
                name="Delete target twice",
                client=real_client,
                method="DELETE",
                url=f"{ingest_api}/datasources/{setup_datasource_id}/targets/{setup_keyword_target_id}",
                expected_status=400,
            )
            archived_datasource_id = create_datasource(
                real_client, ingest_api, setup_project_id or "", make_name("archived_datasource")
            )
            created_datasource_ids.append(archived_datasource_id)
            runner.cleanup_call(
                client=real_client,
                label="archive setup archived datasource",
                method="DELETE",
                url=f"{ingest_api}/datasources/{archived_datasource_id}",
                expected_status=200,
            )
            runner.run_case(
                case_id="TGT-10",
                name="Create target under archived datasource",
                client=real_client,
                method="POST",
                url=f"{ingest_api}/datasources/{archived_datasource_id}/targets/keywords",
                expected_status=400,
                payload={
                    "values": ["archived source keyword"],
                    "crawl_interval_minutes": 11,
                },
            )
        else:
            runner.skip("TGT", "datasource setup unavailable")

    finally:
        print("")
        print("[cleanup]")
        for datasource_id, target_id in reversed(created_target_refs):
            runner.cleanup_call(
                client=real_client,
                label=f"delete target {target_id}",
                method="DELETE",
                url=f"{ingest_api}/datasources/{datasource_id}/targets/{target_id}",
            )
        for datasource_id in reversed(created_datasource_ids):
            runner.cleanup_call(
                client=real_client,
                label=f"archive datasource {datasource_id}",
                method="DELETE",
                url=f"{ingest_api}/datasources/{datasource_id}",
            )
        for project_id in reversed(created_project_ids):
            runner.cleanup_call(
                client=real_client,
                label=f"delete crisis-config {project_id}",
                method="DELETE",
                url=f"{project_api}/projects/{project_id}/crisis-config",
            )
            runner.cleanup_call(
                client=real_client,
                label=f"archive project {project_id}",
                method="DELETE",
                url=f"{project_api}/projects/{project_id}",
            )
        for campaign_id in reversed(created_campaign_ids):
            runner.cleanup_call(
                client=real_client,
                label=f"archive campaign {campaign_id}",
                method="DELETE",
                url=f"{project_api}/campaigns/{campaign_id}",
            )

    return runner.print_summary()


def uuid_like(seed: str) -> str:
    normalized = (seed * 8)[:32]
    return (
        f"{normalized[:8]}-{normalized[8:12]}-{normalized[12:16]}-"
        f"{normalized[16:20]}-{normalized[20:32]}"
    )


if __name__ == "__main__":
    raise SystemExit(main())
