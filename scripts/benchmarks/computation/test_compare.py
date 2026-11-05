"""Guard against publishing a speedup after changing or omitting evidence."""
import copy
import gzip
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("computation_compare", Path(__file__).with_name("compare.py"))
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
record_spec = importlib.util.spec_from_file_location("computation_record", Path(__file__).with_name("record.py"))
record = importlib.util.module_from_spec(record_spec)
record_spec.loader.exec_module(record)


def runner_receipt():
    case_spec = {"id": "example", "subsystem": "test", "description": "Small public workload",
                 "input": {"recipe": [1, 2]}}
    return {
        "version": 1, "label": "fixture", "failures": [], "samples": 3, "target_us": 20000,
        "engine": {"version": "pinned"}, "os": "host",
        "architecture": "test", "display": "headless", "timing_scope": "API",
        "processor": "test processor", "processor_count": 8, "host_label": "fixture-host",
        "execution_flags": ["--headless", "--path", "/reference/project", "--script", "res://runner.gd"],
        "cases": [{
            "id": "example", "subsystem": "test", "description": "Small public workload",
            "input": case_spec,
            "iterations": 2, "durations_us": [20, 22, 24],
            "cold_us": 15, "per_call_us": [10.0, 11.0, 12.0],
            "median_us": 11.0, "min_us": 10.0, "max_us": 12.0,
            "snapshot_bytes": 120, "snapshot_sha256": "a" * 64,
            "snapshot": {"outputs": [3], "cost": 12,
                         "events": [{"cycle": 0, "kind": "read"}, {"cycle": 8, "kind": "output"}]},
        }],
    }


def receipt():
    return record.seal(json.dumps(runner_receipt()).encode("utf-8"), b"PASS fixture\n", 0)


class ComparisonTests(unittest.TestCase):
    def assert_rejected(self, before, after):
        result = module.compare(before, after)
        self.assertFalse(result["passed"])
        self.assertTrue(result["issues"])
        for case in result["cases"]:
            self.assertNotIn("speed_ratio", case)
            self.assertNotIn("time_reduction_percent", case)
        return result

    def test_identical_full_evidence_allows_measured_speed_ratio(self):
        before = receipt()
        after = copy.deepcopy(before)
        after["cases"][0]["durations_us"] = [10, 11, 12]
        result = module.compare(before, after)
        self.assertTrue(result["passed"])
        self.assertEqual(result["cases"][0]["speed_ratio"], 2)
        self.assertTrue(result["cases"][0]["timing_comparable"])

    def test_comparison_recomputes_statistics_from_raw_durations(self):
        after = receipt()
        after["cases"][0]["durations_us"] = [10, 11, 12]
        after["cases"][0]["median_us"] = 99999
        after["cases"][0]["per_call_us"] = [99999, 99999, 99999]
        result = module.compare(receipt(), after)
        self.assertTrue(result["passed"])
        self.assertEqual(result["cases"][0]["candidate_median_us"], 5.5)
        self.assertEqual(result["cases"][0]["speed_ratio"], 2)

    def test_same_score_does_not_hide_changed_or_omitted_trace(self):
        for events in [[{"cycle": 0, "kind": "read"}],
                       [{"cycle": 1, "kind": "read"}, {"cycle": 8, "kind": "output"}]]:
            after = receipt()
            after["cases"][0]["snapshot"]["events"] = events
            self.assert_rejected(receipt(), after)

    def test_missing_duplicate_failed_or_different_work_is_rejected(self):
        variants = []
        value = receipt()
        value["cases"] = []
        variants.append(value)
        value = receipt()
        value["cases"].append(copy.deepcopy(value["cases"][0]))
        variants.append(value)
        value = receipt()
        value["failures"] = ["retained evidence mutated"]
        variants.append(value)
        value = receipt()
        value["cases"][0]["input"]["input"]["recipe"] = [1, 3]
        variants.append(value)
        value = receipt()
        value["cases"][0]["snapshot"]["cost"] = 12.0
        variants.append(value)
        for after in variants:
            self.assert_rejected(receipt(), after)

    def test_different_batches_or_environment_cannot_claim_comparable_speed(self):
        for field, value in [("iterations", 3), ("durations_us", [10, 0, 12]),
                             ("durations_us", [10, 11])]:
            after = receipt()
            after["cases"][0][field] = value
            self.assert_rejected(receipt(), after)
        after = receipt()
        after["architecture"] = "other"
        self.assert_rejected(receipt(), after)

    def test_equal_unsupported_markers_never_establish_parity(self):
        for marker in ("depth", "Callable", "Object"):
            before = receipt()
            before["cases"][0]["snapshot"]["events"][1]["value"] = {"@unsupported": marker}
            self.assert_rejected(before, copy.deepcopy(before))

    def test_missing_top_level_and_case_fields_fail_cleanly_on_both_sides(self):
        original = receipt()
        for key in original:
            with self.subTest(top_level=key):
                before = copy.deepcopy(original)
                del before[key]
                self.assert_rejected(before, copy.deepcopy(before))
        for key in original["cases"][0]:
            with self.subTest(case=key):
                before = copy.deepcopy(original)
                del before["cases"][0][key]
                self.assert_rejected(before, copy.deepcopy(before))

    def test_bad_receipt_container_shapes_fail_cleanly(self):
        for malformed in (None, [], "receipt", 1, True):
            with self.subTest(value=malformed):
                self.assert_rejected(receipt(), malformed)
        for field, values in {
            "cases": [None, {}, [None], ["case"], [{"id": []}]],
            "failures": [None, "", {}, [False]],
            "samples": [True, 3.0, None, {}, 0, 2],
            "engine": [None, "", {}, []],
            "execution_flags": [None, "--headless", [1]],
            "processor_count": [True, 8.0, 0],
            "host_label": ["", None, 1],
            "version": [True, 1.0, None, 2],
        }.items():
            for value in values:
                with self.subTest(field=field, value=value):
                    after = receipt()
                    after[field] = value
                    self.assert_rejected(receipt(), after)

    def test_iteration_counts_are_exact_positive_integers_on_both_sides(self):
        for value in (True, 2.0, 0, -2, "2", None, 10 ** 1000):
            with self.subTest(value=str(value)[:30]):
                before = receipt()
                before["cases"][0]["iterations"] = value
                self.assert_rejected(before, copy.deepcopy(before))

    def test_duration_samples_reject_float_bool_nonfinite_and_invalid_values(self):
        for value in (True, 20.0, 0, -1, "20", None,
                      float("inf"), float("-inf"), float("nan"), 10 ** 1000):
            with self.subTest(value=str(value)[:30]):
                before = receipt()
                before["cases"][0]["durations_us"][0] = value
                self.assert_rejected(before, copy.deepcopy(before))
        for durations in (None, {}, "20,22,24", []):
            after = receipt()
            after["cases"][0]["durations_us"] = durations
            self.assert_rejected(receipt(), after)

    def test_nonfinite_or_unsupported_nested_input_and_snapshot_fail_cleanly(self):
        for field in ("input", "snapshot"):
            for value in (float("nan"), float("inf"), object()):
                after = receipt()
                after["cases"][0][field]["nested"] = [value]
                self.assert_rejected(receipt(), after)

    def test_bad_case_metadata_and_null_evidence_fail_cleanly(self):
        for field, value in (
            ("id", []), ("subsystem", ""), ("description", None),
            ("input", {}), ("snapshot", None), ("snapshot_bytes", True),
            ("snapshot_bytes", 0), ("snapshot_sha256", "not-a-digest"),
            ("cold_us", -1), ("cold_us", True), ("cold_us", 1.5),
            ("per_call_us", [1, None, 3]), ("median_us", float("inf")),
            ("min_us", 0), ("max_us", 10 ** 1000),
        ):
            with self.subTest(field=field, value=str(value)[:30]):
                after = receipt()
                after["cases"][0][field] = value
                self.assert_rejected(receipt(), after)

    def test_equal_values_with_changed_snapshot_metadata_are_rejected(self):
        for field, value in (("snapshot_bytes", 121), ("snapshot_sha256", "b" * 64)):
            after = receipt()
            after["cases"][0][field] = value
            self.assert_rejected(receipt(), after)

    def test_hardware_and_engine_flags_bind_timing_but_project_path_may_differ(self):
        after = receipt()
        after["execution_flags"][2] = "/candidate/project"
        self.assertTrue(module.compare(receipt(), after)["passed"])
        for field, value in (
            ("host_label", "different-host"), ("processor", "other processor"),
            ("processor_count", 16),
            ("execution_flags", ["--headless", "--path", "/reference/project",
                                 "--script", "res://runner.gd", "--single-threaded-scene"]),
        ):
            after = receipt()
            after[field] = value
            self.assert_rejected(receipt(), after)

    def test_cli_bad_json_reports_failed_comparison_without_traceback(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            good = root / "good.json"
            bad = root / "bad.json"
            good.write_text(json.dumps(receipt()), encoding="utf-8")
            bad.write_text("{not-json", encoding="utf-8")
            process = subprocess.run(
                [sys.executable, str(Path(module.__file__)), str(good), str(bad)],
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(process.returncode, 1)
            result = json.loads(process.stdout)
            self.assertFalse(result["passed"])
            self.assertEqual(result["cases"], [])
            self.assertNotIn("Traceback", process.stderr)

    def test_plain_and_gzip_duplicate_fields_fail_closed_before_comparison(self):
        original = json.dumps(receipt(), separators=(",", ":"))
        replacements = (
            ('"failures":[]', '"failures":["incomplete computation"],"failures":[]'),
            ('"returncode":0', '"returncode":1,"returncode":0'),
            ('"diagnostics":[]', '"diagnostics":["SCRIPT ERROR: abort"],"diagnostics":[]'),
        )
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for suffix in (".json", ".json.gz"):
                for old, new in replacements:
                    with self.subTest(suffix=suffix, field=old):
                        self.assertIn(old, original)
                        malformed = original.replace(old, new, 1).encode("utf-8")
                        path = root / ("duplicate" + suffix)
                        path.write_bytes(gzip.compress(malformed, mtime=0)
                                         if suffix.endswith(".gz") else malformed)
                        with self.assertRaisesRegex(ValueError, "Duplicate benchmark receipt JSON field"):
                            module.read(path)
                        process = subprocess.run(
                            [sys.executable, "-B", str(Path(module.__file__)), str(path), str(path)],
                            capture_output=True, text=True, check=False,
                        )
                        self.assertEqual(process.returncode, 1, process.stderr)
                        result = json.loads(process.stdout)
                        self.assertFalse(result["passed"])
                        self.assertEqual(result["cases"], [])
                        self.assertIn("Duplicate benchmark receipt JSON field", result["issues"][0])
                        self.assertNotIn("speed_ratio", process.stdout)
                        self.assertNotIn("time_reduction_percent", process.stdout)
                        self.assertNotIn("Traceback", process.stderr)

    def test_process_seal_retains_raw_fields_and_hashes_complete_bytes(self):
        original = runner_receipt()
        raw = json.dumps(original, ensure_ascii=False, indent=2).encode("utf-8")
        log = b"Godot fixture\r\nPASS: workload\n"
        sealed = record.seal(raw, log, 0)
        self.assertEqual({key: value for key, value in sealed.items() if key != "process"}, original)
        self.assertEqual(sealed["process"], {
            "returncode": 0, "diagnostics": [],
            "raw_sha256": hashlib.sha256(raw).hexdigest(),
            "log_sha256": hashlib.sha256(log).hexdigest(),
        })
        self.assertTrue(module.compare(sealed, copy.deepcopy(sealed))["passed"])
        candidate = copy.deepcopy(original)
        candidate["cases"][0]["durations_us"] = [10, 11, 12]
        after = record.seal(json.dumps(candidate).encode("utf-8"), b"PASS candidate\n", 0)
        self.assertNotEqual(sealed["process"]["raw_sha256"], after["process"]["raw_sha256"])
        self.assertNotEqual(sealed["process"]["log_sha256"], after["process"]["log_sha256"])
        self.assertEqual(module.compare(sealed, after)["cases"][0]["speed_ratio"], 2)

    def test_matching_bad_process_logs_never_self_pass(self):
        raw = json.dumps(runner_receipt()).encode("utf-8")
        for line in (
            b"SCRIPT ERROR: nested validator aborted",
            b"ERROR: Failed to load script", b"Parse Error: Expected parameter",
            b"WARNING: incomplete work",
        ):
            log = b"Godot\n  " + line + b"\nPASS: computation benchmark 12 cases, 0 failures\n"
            sealed = record.seal(raw, log, 0)
            self.assertEqual(sealed["failures"], [])
            self.assertEqual(sealed["process"]["diagnostics"], ["  " + line.decode()])
            self.assert_rejected(sealed, copy.deepcopy(sealed))
        failed = record.seal(raw, b"Godot\n", -15)
        self.assert_rejected(failed, copy.deepcopy(failed))

    def test_missing_or_malformed_process_metadata_is_rejected(self):
        for field in receipt()["process"]:
            before = receipt()
            del before["process"][field]
            self.assert_rejected(before, copy.deepcopy(before))
        for value in (None, [], "", True):
            before = receipt()
            before["process"] = value
            self.assert_rejected(before, copy.deepcopy(before))
        for field, values in {
            "returncode": [True, False, 0.0, None, "0", 1, -9],
            "diagnostics": [None, {}, "", [1], [""], ["SCRIPT ERROR: abort"]],
            "log_sha256": [None, "", "a" * 63, "g" * 64, "A" * 64, 1],
            "raw_sha256": [None, "", "a" * 63, "g" * 64, "A" * 64, 1],
        }.items():
            for value in values:
                before = receipt()
                before["process"][field] = value
                self.assert_rejected(before, copy.deepcopy(before))

    def test_process_seal_rejects_malformed_or_resealed_runner_output(self):
        for raw in (b"{invalid", b"[]", b"null", b'{"x":NaN}', b'{"x":1,"x":2}',
                    json.dumps(receipt()).encode("utf-8")):
            with self.subTest(raw=raw[:40]), self.assertRaises(ValueError):
                record.seal(raw, b"complete log", 0)
        for code in (True, 0.0, None, "0"):
            with self.assertRaises(TypeError):
                record.seal(b"{}", b"log", code)

    def test_process_sealing_cli_archives_failed_receipts_and_protects_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            raw = root / "raw.json"
            log = root / "process.log"
            output = root / "sealed.json.gz"
            raw_bytes = json.dumps(runner_receipt()).encode("utf-8")
            raw.write_bytes(raw_bytes)

            def invoke(target, code=0):
                return subprocess.run(
                    [sys.executable, "-B", str(Path(record.__file__)), str(raw), str(log),
                     "--returncode", str(code), "--output", str(target)],
                    capture_output=True, text=True, check=False,
                )

            for log_bytes, code, expected in (
                (b"PASS fixture\n", 0, True),
                (b"SCRIPT ERROR: abort\nPASS fixture\n", 0, False),
                (b"Godot stopped\n", 2, False),
            ):
                log.write_bytes(log_bytes)
                process = invoke(output, code)
                self.assertEqual(process.returncode, 0 if expected else 1, process.stderr)
                self.assertEqual(json.loads(process.stdout)["passed"], expected)
                sealed = json.loads(gzip.decompress(output.read_bytes()))
                self.assertEqual(module.compare(sealed, sealed)["passed"], expected)
                self.assertEqual(raw.read_bytes(), raw_bytes)
                self.assertEqual(log.read_bytes(), log_bytes)
                self.assertNotIn("Traceback", process.stderr)
            for target in (raw, log):
                before = target.read_bytes()
                process = invoke(target)
                self.assertEqual(process.returncode, 1)
                self.assertEqual(target.read_bytes(), before)
            log.write_bytes(b"PASS fixture\n")
            plain_output = root / "sealed.json"
            process = invoke(plain_output)
            self.assertEqual(process.returncode, 0)
            self.assertTrue(module.compare(module.read(plain_output), module.read(plain_output))["passed"])
            runner_failure = runner_receipt()
            runner_failure["failures"] = ["semantic result rejected"]
            for malformed in (runner_failure, {"version": 1}):
                raw.write_text(json.dumps(malformed), encoding="utf-8")
                process = invoke(output)
                self.assertEqual(process.returncode, 1)
                self.assertFalse(json.loads(process.stdout)["passed"])
                sealed = json.loads(gzip.decompress(output.read_bytes()))
                self.assertEqual({k: v for k, v in sealed.items() if k != "process"}, malformed)
            raw.write_bytes(b"{invalid")
            absent_output = root / "malformed.json"
            process = invoke(absent_output)
            self.assertEqual(process.returncode, 1)
            self.assertFalse(absent_output.exists())
            self.assertFalse(json.loads(process.stdout)["passed"])
            self.assertNotIn("Traceback", process.stderr)


if __name__ == "__main__":
    unittest.main()
