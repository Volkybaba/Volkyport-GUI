# SPDX-License-Identifier: MIT
#
# The Volkyport GUI. Volkyport/pugwash bootstraps pylibs and runs it.

from pathlib import Path

## The pylibs directory, default_theme/, resources/ and locales/ live there.
PYLIB_PATH = Path(__file__).resolve().parent.parent

## Version info. The real values live in the Volkyport/pugwash script (tools/vp_release.py
## and do_release.sh edit them there), which calls set_version_info() before importing
## anything else from pugwash.
VOLKYPORT_VERSION = 'unknown'
VOLKYPORT_RELEASE_CHANNEL = 'developer'
VOLKYPORT_MIN_VERSION = '0'
VOLKYPORT_RELEASE_URL = 'https://github.com/Volkybaba/Volkyport-GUI/releases/latest/download/'
VOLKYPORT_RELEASE_VALUES = ('stable', 'beta', 'alpha')
VOLKYPORT_UPDATE_FREQUENCY = (60 * 60 * 1)
VOLKYPORT_DEBUG = False


def set_version_info(**values):
    """
    Called by the Volkyport/pugwash script with its version block.
    """
    for name, value in values.items():
        if name not in globals() or not name.startswith('VOLKYPORT_'):
            raise ValueError(f"unknown version info {name!r}")

        globals()[name] = value

    import harbourmaster.config
    harbourmaster.config.HM_DEBUG = globals()['VOLKYPORT_DEBUG']
