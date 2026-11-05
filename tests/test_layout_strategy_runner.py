"""Check the actual runner's profile routing before invoking a real engine."""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


RUNNER = Path(__file__).resolve().parents[1] / "scripts" / "run-experiment.py"


class RunnerProfiles(unittest.TestCase):
    def invoke(self, arguments, prepare=True):
        spec = importlib.util.spec_from_file_location("strategy_runner", RUNNER)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "scripts").mkdir()
            original = '[application]\nrun/main_scene="res://journey.tscn"\n'
            (root / "project.godot").write_text(original)
            module.__file__ = str(root / "scripts" / "run-experiment.py")
            profiles = []
            commands = []

            def output(command, **_):
                if command[-1] == "--version":
                    return "4.7.1.stable.official.test"
                self.assertEqual(command[:2], ["git", "ls-files"])
                return b"project.godot\0"

            def run(command, **_):
                commands.append(command)
                project = Path(command[command.index("--path") + 1])
                profiles.append((project / "project.godot").read_text())
                return type("Exit", (), {"returncode": 0})()

            argv = ["run-experiment.py", "layout_strategy", "--godot", "/fake/Godot"]
            argv += ["--prepare-only"] if prepare else []
            argv += arguments
            with patch("sys.argv", argv), patch.object(module.subprocess, "check_output", output), \
                 patch.object(module.subprocess, "run", run), contextlib.redirect_stdout(io.StringIO()), \
                 contextlib.redirect_stderr(io.StringIO()):
                module.main()
            self.assertEqual((root / "project.godot").read_text(), original)
            return profiles, commands

    def test_named_notebook_is_stable_and_never_candidate(self):
        first, commands = self.invoke(["--profile", "research-1"], prepare=False)
        second, _ = self.invoke(["--profile", "research-1"])
        expected = 'config/custom_user_dir_name=' + json.dumps(
            "VonNeumannBottleneckChecks/layout_strategy/research-1")
        for settings in first + second:
            self.assertIn(expected, settings)
            self.assertIn('run/main_scene="res://experiments/layout_strategy/lab.tscn"', settings)
            self.assertNotIn("[candidate]", settings)
        self.assertFalse(any("--candidate-save" in command for command in commands))
        self.assertFalse(any("--candidate-journey" in command for command in commands))

    def test_other_profile_is_separate(self):
        first, _ = self.invoke(["--profile", "one"])
        second, _ = self.invoke(["--profile", "two"])
        self.assertNotEqual(first, second)

    def test_unnamed_copies_remain_isolated(self):
        first, _ = self.invoke([])
        second, _ = self.invoke([])
        self.assertNotEqual(first, second)
        self.assertIn("VonNeumannBottleneckChecks/experiments/", first[0])

    def test_unsafe_and_unsupported_routes_stop_before_engine(self):
        for arguments in [["--profile", "../player"], ["--profile", ""],
                          ["--profile", "a" * 41], ["--profile", "named", "--journey"],
                          ["--profile", "named", "--replay", "lab"], ["--replay", "proxy"]]:
            with self.subTest(arguments=arguments), self.assertRaises(SystemExit) as raised:
                self.invoke(arguments)
            self.assertEqual(raised.exception.code, 2)


if __name__ == "__main__":
    unittest.main()
