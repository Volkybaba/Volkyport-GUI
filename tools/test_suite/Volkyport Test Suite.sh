#!/bin/bash
# VOLKYPORT: pmtest.zip, Volkyport Test Suite.sh
#
# SPDX-License-Identifier: MIT
#
# Installs the Volkyport build in pmtest/Volkyport.zip, runs every test on this
# device, shows a summary and saves a report zip in pmtest/reports/.

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/Volkyport/" ]; then
  controlfolder="/opt/system/Tools/Volkyport"
elif [ -d "/opt/tools/Volkyport/" ]; then
  controlfolder="/opt/tools/Volkyport"
elif [ -d "$XDG_DATA_HOME/Volkyport/" ]; then
  controlfolder="$XDG_DATA_HOME/Volkyport"
else
  controlfolder="/roms/ports/Volkyport"
fi

source $controlfolder/control.txt
[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"
get_controls

## Where the port's folder is: next to this script on most CFWs, in the ports folder otherwise.
GAMEDIR="$(cd "$(dirname "$0")" && pwd)/pmtest"
[ -d "$GAMEDIR" ] || GAMEDIR="/$directory/ports/pmtest"
cd "$GAMEDIR" || exit 1

## The python Volkyport itself uses on this CFW.
if [ -d "/opt/python/bin" ]; then
  ## muOS
  export PATH="/opt/python/bin:$PATH"
  export LD_LIBRARY_PATH="/opt/python/lib:$LD_LIBRARY_PATH"
fi

PY=""
for candidate in "$PM_PYTHON" python3 python; do
  if [ -n "$candidate" ] && command -v "$candidate" > /dev/null 2>&1; then
    PY="$(command -v "$candidate")"
    break
  fi
done

if [ -z "$PY" ]; then
  pm_message "Volkyport Test Suite: no python3 found on this device."
  sleep 5
  pm_finish
  exit 1
fi

export controlfolder
mkdir -p "$GAMEDIR/reports"

pm_platform_helper "$PY"
"$PY" "$GAMEDIR/suite.py" 2>&1 | tee "$GAMEDIR/reports/last-run.txt"

pm_finish
