#!/bin/bash
#
# SPDX-License-Identifier: MIT
#
# Launches Volkyport: everything else lives in $controlfolder/utils/vp_launch.txt

export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/Volkyport/" ]; then
  controlfolder="/opt/system/Tools/Volkyport"
elif [ -d "/opt/tools/Volkyport/" ]; then
  controlfolder="/opt/tools/Volkyport"
elif [ -d "$XDG_DATA_HOME/Volkyport/" ]; then
  controlfolder="$XDG_DATA_HOME/Volkyport"
else
  controlfolder="/roms/ports/Volkyport"
fi

source "$controlfolder/utils/vp_launch.txt"; exit $?
