from os import remove
from os.path import abspath, dirname, isfile, join
from subprocess import run, CompletedProcess
from typing import List
from unittest import TestCase

import requests


TEST_SH_FOLDER = abspath(join(dirname(__file__), "..", ".."))


class GithubIssueTestCase(TestCase):
    _URL_API: str = "https://api.github.com"
    _URL_WEB: str = "https://github.com"
    _OWNER: str = ""
    _REPOSITORY: str = ""

    def assert_github_issue_is_open(self, issue_number: int, msg: str = "") -> None:
        issue_identifier = f"{self._OWNER}/{self._REPOSITORY}/issues/{issue_number}"
        state = requests.get(f"{self._URL_API}/repos/{issue_identifier}").json()["state"]

        self.assertEqual(
            state,
            "open",
            msg=f"GitHub issue {self._URL_WEB}/{issue_identifier} is no longer open.{msg}",
        )

    def assert_released_after_fix(self, last_release_count: int) -> None:
        releases_url = (
            f"{self._URL_API}/repos/{self._OWNER}/{self._REPOSITORY}/git/refs/tags"
        )
        releases = requests.get(releases_url).json()

        self.assertLessEqual(len(releases), last_release_count)


class TestSH(TestCase):
    FILE_NAME = "test.sh"
    FILE_LOCATION = join(TEST_SH_FOLDER, FILE_NAME)

    @staticmethod
    def test_file_exists():
        assert isfile(TestSH.FILE_LOCATION), f"File not found in '{TestSH.FILE_LOCATION}'"


class TestShRcFile(TestSH):
    RC_FILE_LOCATION = join(TEST_SH_FOLDER, ".testrc")

    OFFSET_ERROR_MSG = (
        f"The '{TestSH.FILE_NAME}' RC file is malformed. "
        f"Check the '{TestSH.FILE_LOCATION}' file, line starting with "
        "'declare -A TEST_RC_FILE_HEAD_OFFSET' if the '{key_name}' offset is correct."
    )

    def _cleanup(self):
        try:
            remove(self.RC_FILE_LOCATION)
        except FileNotFoundError:
            pass

    def setUp(self):
        self._cleanup()

    def tearDown(self):
        self._cleanup()

    @staticmethod
    def _generate_rc_file() -> CompletedProcess:
        return run(["bash", TestSH.FILE_LOCATION, "--generate-rc-file"])

    def test_it_can_generate_dot_testrc_file(self):
        self.assertEqual(self._generate_rc_file().returncode, 0)

    def test_it_produces_valid_dot_testrc_file(self):
        self._generate_rc_file()

        rc_file_lines: List[str] = list(open(self.RC_FILE_LOCATION, "r"))

        assert rc_file_lines[0].startswith(
            "# Uncomment only lines you need to change."
        ), self.OFFSET_ERROR_MSG.format(key_name="start")

        assert rc_file_lines[-1].startswith(
            "#TODOS_LIMIT_PER_PERSON="
        ), self.OFFSET_ERROR_MSG.format(key_name="end")


class BugsInSafetyAreFixedTestCase(GithubIssueTestCase):
    _OWNER = "pyupio"
    _REPOSITORY = "safety"

    def test_safety_cannot_be_enable_on_windows(self):
        """
        See details of the issue:
        https://github.com/pyupio/safety/issues/119#issuecomment-511828226

        To re-test, remove the OS related conditions around safety in test.sh
        and re-run on windows. Search for 'if [[ ${use_safety} == true ]]; then'

        To test a failing library, use::

            requests==2.19.1

        """
        self.assert_github_issue_is_open(119, "Check if safety can be enabled on Windows.")
