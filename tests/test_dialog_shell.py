# SPDX-License-Identifier: MIT
#
# Volkyport/VolkyportDialog.txt, the shell side of fifo_control: how it waits for
# pugwash's answer. Runs a copy with /dev/shm/volkyport moved into tmp_path, and a
# fake pugwash (a background shell) writing the done file.

import shutil
import subprocess
import time

import pytest

from conftest import PM_DIR


pytestmark = pytest.mark.skipif(shutil.which("bash") is None, reason="needs bash")


@pytest.fixture
def dialog(tmp_path):
    shm = tmp_path / "shm"
    copy = tmp_path / "VolkyportDialog.txt"
    copy.write_text((PM_DIR / "VolkyportDialog.txt").read_text().replace("/dev/shm/volkyport", str(shm)))

    def run(script, timeout=30):
        started = time.monotonic()
        result = subprocess.run(
            ## As after VolkyportDialogInit: the pipe is there and pugwash has answered DONE.
            ["bash", "-c", f'source "{copy}"\n: > "$PM_PIPE"\nprintf DONE > "$PM_DONE"\n{script}'],
            env={'PATH': "/usr/bin:/bin", 'HOME': str(tmp_path), 'ESUDO': ""}, cwd=str(tmp_path), timeout=timeout,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, universal_newlines=True)

        assert result.returncode == 0, result.stdout
        return result.stdout.strip().splitlines()[-1], time.monotonic() - started

    return run


def test_empty_answer_is_still_waiting(dialog):
    ## An older pugwash truncates the done file before writing the answer: the
    ## script must not take the empty file as the answer (x55, 2026-10-13).
    answer, _ = dialog(
        '(sleep 0.5; : > "$PM_DONE"; sleep 0.7; printf OKAY > "$PM_DONE") &\n'
        'PM_PID=$!\n'
        'VolkyportDialogResult install /tmp/x.zip')

    assert answer == "OKAY"


def test_stops_waiting_when_pugwash_is_gone(dialog):
    ## Nobody left to answer: give up instead of waiting 30 minutes.
    answer, took = dialog(
        'sleep 0.2 &\n'
        'PM_PID=$!\n'
        'VolkyportDialogResult message hello')

    assert answer == "WAIT"
    assert took < 10
