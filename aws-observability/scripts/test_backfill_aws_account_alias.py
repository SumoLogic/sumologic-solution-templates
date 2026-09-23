"""
Tests for backfill_aws_account_alias.py

Run: python3 -m pytest test_backfill_aws_account_alias.py -v
"""

import importlib.util
import logging
import os
import sys

import pytest
from unittest.mock import patch, MagicMock

SCRIPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "backfill_aws_account_alias.py")
spec = importlib.util.spec_from_file_location("backfill_aws_account_alias", SCRIPT_PATH)
script = importlib.util.module_from_spec(spec)
spec.loader.exec_module(script)
sys.modules["backfill_aws_account_alias"] = script


# ─── URL Construction ────────────────────────────────────────────────────────


class TestBuildBaseUrl:
    def test_us(self):
        assert script.build_base_url("us") == "https://api.sumologic.com/api/v1"

    def test_regional_au(self):
        assert script.build_base_url("au") == "https://api.au.sumologic.com/api/v1"

    def test_regional_de(self):
        assert script.build_base_url("de") == "https://api.de.sumologic.com/api/v1"

    def test_staging(self):
        assert script.build_base_url("stag") == "https://stag-api.sumologic.net/api/v1"

    def test_long(self):
        assert script.build_base_url("long") == "https://long-api.sumologic.net/api/v1"


# ─── Collector Pattern Matching ──────────────────────────────────────────────


class TestExtractAccountId:
    def test_standard_format(self):
        assert script.extract_account_id("aws-observability-123456789012-123456789012") == "123456789012"

    def test_account_id_with_region(self):
        assert script.extract_account_id("aws-observability-658469472519-us-east-1") == "658469472519"

    def test_account_id_only_suffix(self):
        assert script.extract_account_id("aws-observability-658469472519") == "658469472519"

    def test_non_matching_name(self):
        assert script.extract_account_id("some-other-collector") is None

    def test_short_number_not_12_digits(self):
        assert script.extract_account_id("aws-observability-12345-12345") is None

    def test_no_number(self):
        assert script.extract_account_id("aws-observability-prod") is None


# ─── Alias Validation ───────────────────────────────────────────────────────


class TestValidateAlias:
    def test_valid_alias(self):
        assert script.validate_alias("prod-account") is None

    def test_valid_alias_digits(self):
        assert script.validate_alias("account123") is None

    def test_valid_alias_min_length(self):
        assert script.validate_alias("abc") is None

    def test_too_short(self):
        error = script.validate_alias("ab")
        assert "3-63 chars" in error

    def test_too_long(self):
        error = script.validate_alias("a" * 64)
        assert "3-63 chars" in error

    def test_uppercase_rejected(self):
        error = script.validate_alias("Prod-Account")
        assert "lowercase" in error

    def test_consecutive_hyphens(self):
        error = script.validate_alias("prod--account")
        assert "consecutive hyphens" in error

    def test_starts_with_hyphen(self):
        error = script.validate_alias("-prod")
        assert "no leading/trailing" in error

    def test_ends_with_hyphen(self):
        error = script.validate_alias("prod-")
        assert "no leading/trailing" in error

    def test_special_chars_rejected(self):
        error = script.validate_alias("prod_account")
        assert "lowercase" in error


# ─── CSV Write and Read ──────────────────────────────────────────────────────


class TestCsvWriteRead:
    def test_write_and_read_roundtrip(self, tmp_path):
        csv_path = str(tmp_path / "test.csv")
        rows = [
            {
                "collector_id": "1",
                "collector_name": "aws-observability-111222333444-111222333444",
                "source_id": "10",
                "source_name": "my-source",
                "accountid": "111222333444",
                "alias": "",
                "override_account_field_with_alias": "No",
            }
        ]
        script.write_csv(rows, csv_path)

        result = script.read_csv(csv_path)
        assert len(result) == 1
        assert result[0]["collector_id"] == "1"
        assert result[0]["collector_name"] == "aws-observability-111222333444-111222333444"
        assert result[0]["source_id"] == "10"
        assert result[0]["source_name"] == "my-source"
        assert result[0]["accountid"] == "111222333444"
        assert result[0]["override_account_field_with_alias"] == "No"

    def test_read_picks_up_user_edits(self, tmp_path):
        csv_path = str(tmp_path / "test.csv")
        rows = [
            {
                "collector_id": "1",
                "collector_name": "col1",
                "source_id": "10",
                "source_name": "src1",
                "accountid": "111222333444",
                "alias": "",
                "override_account_field_with_alias": "No",
            }
        ]
        script.write_csv(rows, csv_path)

        # Simulate user editing the file
        with open(csv_path, "w", newline="") as f:
            f.write("collector_id,collector_name,source_id,source_name,accountid,alias,override_account_field_with_alias\n")
            f.write("1,col1,10,src1,111222333444,prod-account,Yes\n")

        result = script.read_csv(csv_path)
        assert result[0]["alias"] == "prod-account"
        assert result[0]["override_account_field_with_alias"] == "Yes"


# ─── Phase 1: Generate CSV ───────────────────────────────────────────────────


class TestPhase1:
    def test_includes_source_with_accountid_matching_collector(self, tmp_path, capsys):
        session = MagicMock()
        csv_path = str(tmp_path / "output.csv")

        collectors_resp = MagicMock(status_code=200)
        collectors_resp.json.return_value = {
            "collectors": [{"id": 1, "name": "aws-observability-658469472519-658469472519"}]
        }

        sources_resp = MagicMock(status_code=200)
        sources_resp.json.return_value = {
            "sources": [
                {"id": 10, "name": "src-no-fields", "fields": {}},
                {"id": 11, "name": "src-accountid-match", "fields": {"accountid": "658469472519"}},
                {"id": 12, "name": "src-accountid-mismatch", "fields": {"accountid": "999999999999"}},
            ]
        }

        session.get.side_effect = [collectors_resp, sources_resp]

        mock_args = MagicMock(access_id="id", deploy_env="au")
        with patch.object(script, "CSV_FILE", csv_path):
            count = script.step1_prepare(session, "http://base", csv_path, mock_args)

        assert count == 0
        rows = script.read_csv(csv_path)
        assert len(rows) == 1
        assert rows[0]["source_name"] == "src-accountid-match"
        assert rows[0]["alias"] == ""

    def test_includes_source_with_account_matching_collector(self, tmp_path, capsys):
        session = MagicMock()
        csv_path = str(tmp_path / "output.csv")

        collectors_resp = MagicMock(status_code=200)
        collectors_resp.json.return_value = {
            "collectors": [{"id": 1, "name": "aws-observability-658469472519-658469472519"}]
        }

        sources_resp = MagicMock(status_code=200)
        sources_resp.json.return_value = {
            "sources": [
                {"id": 10, "name": "src-account-match", "fields": {"account": "658469472519"}},
                {"id": 11, "name": "src-account-mismatch", "fields": {"account": "other-value"}},
            ]
        }

        session.get.side_effect = [collectors_resp, sources_resp]

        mock_args = MagicMock(access_id="id", deploy_env="au")
        count = script.step1_prepare(session, "http://base", csv_path, mock_args)

        assert count == 0
        rows = script.read_csv(csv_path)
        assert len(rows) == 1
        assert rows[0]["source_name"] == "src-account-match"
        assert rows[0]["alias"] == ""

    def test_autofills_alias_when_both_exist_accountid_matches_and_account_differs(self, tmp_path):
        """Condition 3: both exist, account != accountid, accountid matches collector → autofill alias."""
        session = MagicMock()
        csv_path = str(tmp_path / "output.csv")

        collectors_resp = MagicMock(status_code=200)
        collectors_resp.json.return_value = {
            "collectors": [{"id": 1, "name": "aws-observability-658469472519-658469472519"}]
        }

        sources_resp = MagicMock(status_code=200)
        sources_resp.json.return_value = {
            "sources": [
                {"id": 10, "name": "already-aliased", "fields": {"accountid": "658469472519", "account": "prod-alias"}},
            ]
        }

        session.get.side_effect = [collectors_resp, sources_resp]

        mock_args = MagicMock(access_id="id", deploy_env="au")
        count = script.step1_prepare(session, "http://base", csv_path, mock_args)
        assert count == 0
        rows = script.read_csv(csv_path)
        assert len(rows) == 1
        assert rows[0]["source_name"] == "already-aliased"
        assert rows[0]["alias"] == "prod-alias"

    def test_no_autofill_when_both_exist_account_matches_and_accountid_differs(self, tmp_path):
        """Condition 4: both exist, account != accountid, account matches collector → no autofill."""
        session = MagicMock()
        csv_path = str(tmp_path / "output.csv")

        collectors_resp = MagicMock(status_code=200)
        collectors_resp.json.return_value = {
            "collectors": [{"id": 1, "name": "aws-observability-658469472519-658469472519"}]
        }

        sources_resp = MagicMock(status_code=200)
        sources_resp.json.return_value = {
            "sources": [
                {"id": 10, "name": "account-matches", "fields": {"accountid": "other-value", "account": "658469472519"}},
            ]
        }

        session.get.side_effect = [collectors_resp, sources_resp]

        mock_args = MagicMock(access_id="id", deploy_env="au")
        count = script.step1_prepare(session, "http://base", csv_path, mock_args)
        assert count == 0
        rows = script.read_csv(csv_path)
        assert len(rows) == 1
        assert rows[0]["source_name"] == "account-matches"
        assert rows[0]["alias"] == ""

    def test_no_autofill_when_account_equals_accountid(self, tmp_path):
        """Both exist but account == accountid == collector's ID → no autofill."""
        session = MagicMock()
        csv_path = str(tmp_path / "output.csv")

        collectors_resp = MagicMock(status_code=200)
        collectors_resp.json.return_value = {
            "collectors": [{"id": 1, "name": "aws-observability-658469472519-658469472519"}]
        }

        sources_resp = MagicMock(status_code=200)
        sources_resp.json.return_value = {
            "sources": [
                {"id": 10, "name": "both-equal", "fields": {"accountid": "658469472519", "account": "658469472519"}},
            ]
        }

        session.get.side_effect = [collectors_resp, sources_resp]

        mock_args = MagicMock(access_id="id", deploy_env="au")
        count = script.step1_prepare(session, "http://base", csv_path, mock_args)
        assert count == 0
        rows = script.read_csv(csv_path)
        assert len(rows) == 1
        assert rows[0]["alias"] == ""

    def test_no_matching_collectors(self, tmp_path, capsys):
        session = MagicMock()
        csv_path = str(tmp_path / "output.csv")

        collectors_resp = MagicMock(status_code=200)
        collectors_resp.json.return_value = {
            "collectors": [{"id": 1, "name": "hosted-collector-prod"}]
        }

        session.get.side_effect = [collectors_resp]

        mock_args = MagicMock(access_id="id", deploy_env="au")
        count = script.step1_prepare(session, "http://base", csv_path, mock_args)
        assert count == 0


# ─── Step 2: Apply Changes ───────────────────────────────────────────────────


class TestStep2Apply:
    def _make_args(self, **overrides):
        args = MagicMock(dry_run=False, yes=True)
        for k, v in overrides.items():
            setattr(args, k, v)
        return args

    def test_applies_alias_for_yes_rows(self, tmp_path):
        session = MagicMock()
        csv_path = str(tmp_path / "input.csv")

        with open(csv_path, "w", newline="") as f:
            f.write("collector_id,collector_name,source_id,source_name,accountid,alias,override_account_field_with_alias\n")
            f.write("1,aws-observability-111222333444-111222333444,10,my-source,111222333444,prod-alias,Yes\n")

        etag_resp = MagicMock(status_code=200)
        etag_resp.headers = {"etag": '"abc"'}
        etag_resp.json.return_value = {"source": {"id": 10, "name": "my-source", "fields": {}}}

        put_resp = MagicMock(status_code=200)

        session.get.side_effect = [etag_resp]
        session.put.return_value = put_resp

        result = script.step2_apply(session, "http://base", csv_path, self._make_args())

        assert result == 0
        session.put.assert_called_once()
        call_json = session.put.call_args[1]["json"]
        assert call_json["source"]["fields"]["account"] == "prod-alias"

    def test_skips_no_rows(self, tmp_path, caplog):
        session = MagicMock()
        csv_path = str(tmp_path / "input.csv")

        with open(csv_path, "w", newline="") as f:
            f.write("collector_id,collector_name,source_id,source_name,accountid,alias,override_account_field_with_alias\n")
            f.write("1,col1,10,src1,111222333444,some-alias,No\n")

        with caplog.at_level(logging.INFO):
            result = script.step2_apply(session, "http://base", csv_path, self._make_args())

        assert result == 0
        session.put.assert_not_called()
        assert "Nothing to apply" in caplog.text

    def test_skips_yes_without_alias(self, tmp_path, capsys):
        session = MagicMock()
        csv_path = str(tmp_path / "input.csv")

        with open(csv_path, "w", newline="") as f:
            f.write("collector_id,collector_name,source_id,source_name,accountid,alias,override_account_field_with_alias\n")
            f.write("1,col1,10,src1,111222333444,,Yes\n")

        result = script.step2_apply(session, "http://base", csv_path, self._make_args())

        assert result == 0
        session.put.assert_not_called()

    def test_skips_invalid_alias_with_warning(self, tmp_path, caplog):
        session = MagicMock()
        csv_path = str(tmp_path / "input.csv")

        with open(csv_path, "w", newline="") as f:
            f.write("collector_id,collector_name,source_id,source_name,accountid,alias,override_account_field_with_alias\n")
            f.write("1,col1,10,src1,111222333444,AB,Yes\n")

        with caplog.at_level(logging.WARNING):
            result = script.step2_apply(session, "http://base", csv_path, self._make_args())

        assert result == 0
        session.put.assert_not_called()
        assert "WARNING" in caplog.text
        assert "3-63 chars" in caplog.text

    def test_skips_invalid_but_applies_valid(self, tmp_path, caplog):
        session = MagicMock()
        csv_path = str(tmp_path / "input.csv")

        with open(csv_path, "w", newline="") as f:
            f.write("collector_id,collector_name,source_id,source_name,accountid,alias,override_account_field_with_alias\n")
            f.write("1,col1,10,src1,111222333444,Prod--Account,Yes\n")
            f.write("1,col1,11,src2,111222333444,valid-alias,Yes\n")

        etag_resp = MagicMock(status_code=200)
        etag_resp.headers = {"etag": '"abc"'}
        etag_resp.json.return_value = {"source": {"id": 11, "name": "src2", "fields": {}}}
        put_resp = MagicMock(status_code=200)

        session.get.side_effect = [etag_resp]
        session.put.return_value = put_resp

        with caplog.at_level(logging.INFO):
            result = script.step2_apply(session, "http://base", csv_path, self._make_args())

        assert result == 0
        session.put.assert_called_once()
        assert "WARNING" in caplog.text
        assert "skipped 1" in caplog.text

    def test_missing_ids_reports_error(self, tmp_path, caplog):
        session = MagicMock()
        csv_path = str(tmp_path / "input.csv")

        with open(csv_path, "w", newline="") as f:
            f.write("collector_id,collector_name,source_id,source_name,accountid,alias,override_account_field_with_alias\n")
            f.write(",col1,,src1,111222333444,prod-alias,Yes\n")

        with caplog.at_level(logging.ERROR):
            result = script.step2_apply(session, "http://base", csv_path, self._make_args())

        assert result == 1
        session.put.assert_not_called()
        assert "Missing collector_id or source_id" in caplog.text


# ─── API Retry Logic ─────────────────────────────────────────────────────────


class TestApiGet:
    @patch("backfill_aws_account_alias.time.sleep")
    def test_retries_on_429(self, mock_sleep):
        session = MagicMock()
        r429 = MagicMock(status_code=429)
        r200 = MagicMock(status_code=200)
        session.get.side_effect = [r429, r200]

        result = script.api_get(session, "http://test.com")
        assert result.status_code == 200
        assert session.get.call_count == 2

    @patch("backfill_aws_account_alias.time.sleep")
    def test_retries_on_500(self, mock_sleep):
        session = MagicMock()
        r500 = MagicMock(status_code=500)
        r200 = MagicMock(status_code=200)
        session.get.side_effect = [r500, r200]

        result = script.api_get(session, "http://test.com")
        assert result.status_code == 200

    def test_no_retry_on_success(self):
        session = MagicMock()
        r200 = MagicMock(status_code=200)
        session.get.return_value = r200

        result = script.api_get(session, "http://test.com")
        assert session.get.call_count == 1


class TestApiPut:
    @patch("backfill_aws_account_alias.time.sleep")
    def test_retries_on_429(self, mock_sleep):
        session = MagicMock()
        r429 = MagicMock(status_code=429)
        r200 = MagicMock(status_code=200)
        session.put.side_effect = [r429, r200]

        result = script.api_put(session, "http://test.com", {"data": 1}, '"etag"')
        assert result.status_code == 200
        assert session.put.call_count == 2


# ─── Session Creation ────────────────────────────────────────────────────────


class TestCreateSession:
    def test_creates_session_with_auth(self):
        session = script.create_session("my-id", "my-key")
        assert session.auth == ("my-id", "my-key")
        assert session.headers["Content-Type"] == "application/json"


# ─── Pagination ──────────────────────────────────────────────────────────────


class TestGetAllCollectors:
    def test_single_page(self):
        session = MagicMock()
        resp = MagicMock(status_code=200)
        resp.json.return_value = {"collectors": [{"id": 1, "name": "c1"}]}
        session.get.return_value = resp

        result = script.get_all_collectors(session, "http://base")
        assert len(result) == 1

    def test_pagination_stops_on_empty(self):
        session = MagicMock()
        page1 = MagicMock(status_code=200)
        page1.json.return_value = {"collectors": [{"id": i, "name": f"c{i}"} for i in range(1000)]}

        page2 = MagicMock(status_code=200)
        page2.json.return_value = {"collectors": []}

        session.get.side_effect = [page1, page2]

        result = script.get_all_collectors(session, "http://base")
        assert len(result) == 1000


# ─── End-to-End Main ─────────────────────────────────────────────────────────


class TestMainStep1:
    @patch("backfill_aws_account_alias.requests.Session")
    def test_step1_generates_csv_and_prints_next_command(self, MockSession, tmp_path, caplog, monkeypatch):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setenv("SUMO_ACCESS_KEY", "test-key")

        session = MagicMock()
        MockSession.return_value = session

        collectors_resp = MagicMock(status_code=200)
        collectors_resp.json.return_value = {
            "collectors": [{"id": 1, "name": "aws-observability-111222333444-111222333444"}]
        }

        sources_resp = MagicMock(status_code=200)
        sources_resp.json.return_value = {
            "sources": [{"id": 10, "name": "my-source", "fields": {"account": "111222333444"}}]
        }

        session.get.side_effect = [collectors_resp, sources_resp]

        with caplog.at_level(logging.INFO):
            exit_code = script.main([
                "--access-id", "test-id",
                "--deploy-env", "au",
            ])

        assert exit_code == 0
        session.put.assert_not_called()
        assert "is prepared" in caplog.text
        assert "--filename" in caplog.text
        assert os.path.isfile(str(tmp_path / "backfill_aws_account_alias.csv"))


class TestMainStep2:
    @patch("backfill_aws_account_alias.requests.Session")
    def test_step2_applies_from_csv(self, MockSession, tmp_path, caplog, monkeypatch):
        monkeypatch.setenv("SUMO_ACCESS_KEY", "test-key")
        csv_path = str(tmp_path / "edited.csv")
        with open(csv_path, "w", newline="") as f:
            f.write("collector_id,collector_name,source_id,source_name,accountid,alias,override_account_field_with_alias\n")
            f.write("1,aws-observability-111222333444-111222333444,10,my-source,111222333444,my-alias,Yes\n")

        session = MagicMock()
        MockSession.return_value = session

        etag_resp = MagicMock(status_code=200)
        etag_resp.headers = {"etag": '"xyz"'}
        etag_resp.json.return_value = {"source": {"id": 10, "name": "my-source", "fields": {}}}

        put_resp = MagicMock(status_code=200)

        session.get.side_effect = [etag_resp]
        session.put.return_value = put_resp

        with caplog.at_level(logging.INFO):
            exit_code = script.main([
                "--access-id", "test-id",
                "--deploy-env", "au",
                "--filename", csv_path,
            ])

        assert exit_code == 0
        session.put.assert_called_once()
        call_json = session.put.call_args[1]["json"]
        assert call_json["source"]["fields"]["account"] == "my-alias"
        assert "Updated" in caplog.text


# ─── Log Directory ──────────────────────────────────────────────────────────


class TestLogDir:
    def _make_session_mock(self):
        session = MagicMock()
        collectors_resp = MagicMock(status_code=200)
        collectors_resp.json.return_value = {"collectors": []}
        session.get.return_value = collectors_resp
        return session

    @patch("backfill_aws_account_alias.requests.Session")
    def test_log_file_in_current_dir_by_default(self, MockSession, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setenv("SUMO_ACCESS_KEY", "key")
        MockSession.return_value = self._make_session_mock()

        script.main([
            "--access-id", "id",
            "--deploy-env", "us",
        ])

        assert os.path.isfile(str(tmp_path / "backfill_aws_account_alias.log"))

    @patch("backfill_aws_account_alias.requests.Session")
    def test_log_file_in_specified_dir(self, MockSession, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setenv("SUMO_ACCESS_KEY", "key")
        log_dir = str(tmp_path / "logs")
        MockSession.return_value = self._make_session_mock()

        script.main([
            "--access-id", "id",
            "--deploy-env", "us",
            "--log-dir", log_dir,
        ])

        assert os.path.isfile(os.path.join(log_dir, "backfill_aws_account_alias.log"))

    @patch("backfill_aws_account_alias.requests.Session")
    def test_log_dir_created_if_missing(self, MockSession, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setenv("SUMO_ACCESS_KEY", "key")
        log_dir = str(tmp_path / "nested" / "log" / "dir")
        MockSession.return_value = self._make_session_mock()

        assert not os.path.isdir(log_dir)

        script.main([
            "--access-id", "id",
            "--deploy-env", "us",
            "--log-dir", log_dir,
        ])

        assert os.path.isdir(log_dir)
        assert os.path.isfile(os.path.join(log_dir, "backfill_aws_account_alias.log"))

    @patch("backfill_aws_account_alias.requests.Session")
    def test_log_file_appends_on_subsequent_runs(self, MockSession, tmp_path, monkeypatch):
        monkeypatch.chdir(tmp_path)
        monkeypatch.setenv("SUMO_ACCESS_KEY", "key")
        MockSession.return_value = self._make_session_mock()

        log_path = str(tmp_path / "backfill_aws_account_alias.log")
        with open(log_path, "w", encoding="utf-8") as f:
            f.write("pre-existing line\n")

        script.main([
            "--access-id", "id",
            "--deploy-env", "us",
        ])

        with open(log_path, encoding="utf-8") as f:
            content = f.read()
        assert "pre-existing line" in content
        assert "Log file:" in content
