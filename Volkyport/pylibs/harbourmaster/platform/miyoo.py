# SPDX-License-Identifier: MIT
#
# Miyoo and spruceOS.

import os
import shutil
from pathlib import Path
from loguru import logger
from ..util import replace_file
from .base import PlatformBase


class PlatformMiyoo(PlatformBase):
    WANT_XBOX_FIX = True

    def first_run(self):
        self.volkyport_install([])

    def volkyport_install(self, bash_files):
        """
        Move files into place.
        """
        super().volkyport_install(bash_files)

        MY_DIR = self.hm.tools_dir / "Volkyport" / "miyoo"
        PM_DIR = self.hm.tools_dir / "Volkyport"

        # ACTIVATE THE CONTROL
        logger.debug(f'Copy {MY_DIR / "control.txt"} -> {PM_DIR / "control.txt"}')
        shutil.copy(MY_DIR / "control.txt", PM_DIR / "control.txt")

        # ACTIVATE THE VOLKYPORT
        logger.debug(f'Copy {MY_DIR / "Volkyport.txt"} -> {PM_DIR / "Volkyport.sh"}')
        replace_file(MY_DIR / "Volkyport.txt", PM_DIR / "Volkyport.sh")

        bash_files.append(PM_DIR / "Volkyport.sh")

        # CONTROL HACK
        CONTROL_HACK = Path("/root/.local/share/Volkyport/control.txt")
        if not CONTROL_HACK.parent.is_dir():
            CONTROL_HACK.parent.mkdir(parents=True)

        logger.debug(f'Copy {MY_DIR / "control.txt"} -> {CONTROL_HACK}')
        shutil.copy(MY_DIR / "control.txt", CONTROL_HACK)


class PlatformSpruce(PlatformBase):
    WANT_XBOX_FIX = True

    def first_run(self):
        self.volkyport_install([])

    def volkyport_install(self, bash_files):
        """
        Move files into place.
        """
        super().volkyport_install(bash_files)

        SP_DIR = self.hm.tools_dir / "Volkyport" / "spruce"
        PM_DIR = self.hm.tools_dir / "Volkyport"

        logger.debug(f'Copy {SP_DIR / "control.txt"} -> {PM_DIR / "control.txt"}')
        shutil.copy(SP_DIR / "control.txt", PM_DIR / "control.txt")

        logger.debug(f'Copy {SP_DIR / "Volkyport.txt"} -> {PM_DIR / "Volkyport.sh"}')
        replace_file(SP_DIR / "Volkyport.txt", PM_DIR / "Volkyport.sh")

        bash_files.append(PM_DIR / "Volkyport.sh")

        XDG_DATA_HOME = Path(os.environ.get('XDG_DATA_HOME', Path.home() / '.local' / 'share'))
        CONTROL_HACK = XDG_DATA_HOME / "Volkyport" / "control.txt"
        CONTROL_HACK.parent.mkdir(parents=True, exist_ok=True)

        logger.debug(f'Copy {SP_DIR / "control.txt"} -> {CONTROL_HACK}')
        shutil.copy(SP_DIR / "control.txt", CONTROL_HACK)

    def volkyport_post_install(self):
        self.volkyport_install([])
