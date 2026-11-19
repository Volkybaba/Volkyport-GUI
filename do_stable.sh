#!/bin/bash
#
# SPDX-License-Identifier: MIT
#

./do_i18n.sh

python3 tools/vp_release.py stable "$@"

git add Volkyport/

git commit
