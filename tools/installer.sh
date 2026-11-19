#!/bin/bash
#
# SPDX-License-Identifier: MIT
#
# Install.Volkyport.sh: run by the makeself archive (tools/makeself-header.sh), next
# to Volkyport.zip (and runtimes.zip for the "Full" installers).
#
# This is a FACTORY RESET: everything in Volkyport/ is removed except the runtimes
# (libs/*.squashfs), then Volkyport.zip is unpacked fresh. The Restore.Volkyport.zip
# port relies on that, keep it.
#
# Where things go is worked out the same way as harbourmaster's config.detect_paths(),
# in the same order; tests/test_installer.py checks the two agree.
#
# For the tests only:
#   PM_INSTALL_ROOT=<dir>   a fake filesystem root every path is looked up / written under.
#   PM_INSTALL_DETECT=Y     print what was detected and exit.
#   PM_CUR_TTY=<file>       the console to write to, instead of /dev/tty0.

R="${PM_INSTALL_ROOT:-}"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

NO_SUDO="N"
ESUDO=""
CUR_TTY="${PM_CUR_TTY:-/dev/tty0}"
OS_NAME_OVERRIDE=""
NO_FRONTEND_RESTART=""
BATOCERA_LIKE=""

## -- Where is Volkyport going? -----------------------------------------------
retrodeck_paths() {
  if [ -z "$ports_folder" ]; then
    ports_folder="$rdhome/Volkyport"
  fi

  if [ -z "$roms_folder" ]; then
    roms_folder="$rdhome/roms"
  fi

  export directory="$ports_folder"
  OS_NAME_OVERRIDE="retrodeck"
  NO_SUDO="Y"
  NO_FRONTEND_RESTART="Y"
  CUR_TTY="${PM_CUR_TTY:-/dev/null}"
}

retrodeck_cfg_value() {
  grep "$1" "$2" | awk -F= '{print $2}'
}

## retrodeck.json: "paths": {"rd_home_path": "...", ...}, one key per line.
retrodeck_json_value() {
  sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$2" | head -n 1
}

retrodeck_json_paths() {
  rdhome="$(retrodeck_json_value rd_home_path "$1")"
  roms_folder="$(retrodeck_json_value roms_path "$1")"
  ports_folder="$(retrodeck_json_value portmaster_path "$1")"
  [ -z "$ports_folder" ] && ports_folder="$(retrodeck_json_value ports_path "$1")"
}

if [ -f "$R/var/config/retrodeck/retrodeck.json" ]; then
  ## RetroDECK (0.9+), run inside its flatpak
  export LD_PRELOAD=""
  retrodeck_json_paths "$R/var/config/retrodeck/retrodeck.json"
  export controlfolder="/var/data"
  retrodeck_paths

elif [ -f "$R$HOME/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.json" ]; then
  ## RetroDECK (0.9+), run from outside its flatpak
  export LD_PRELOAD=""
  retrodeck_json_paths "$R$HOME/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.json"
  export controlfolder="$HOME/.var/app/net.retrodeck.retrodeck/data"
  retrodeck_paths

elif [ -f "$R/app/bin/retrodeck.sh" ]; then
  ## RetroDECK, run inside its flatpak
  export LD_PRELOAD=""
  # loading the RetroDECK framework that even give access to variables such as roms_folder
  source "$R/app/libexec/global.sh"
  export controlfolder="/var/data"
  retrodeck_paths

elif [ -f "$R/var/config/retrodeck/retrodeck.cfg" ]; then
  ## RetroDECK, fallback
  export LD_PRELOAD=""
  ports_folder="$(retrodeck_cfg_value ports_folder "$R/var/config/retrodeck/retrodeck.cfg")"
  roms_folder="$(retrodeck_cfg_value roms_folder "$R/var/config/retrodeck/retrodeck.cfg")"
  rdhome="$(retrodeck_cfg_value rdhome "$R/var/config/retrodeck/retrodeck.cfg")"
  export controlfolder="/var/data"
  retrodeck_paths

elif [ -f "$R$HOME/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.cfg" ]; then
  ## RetroDECK, run from outside its flatpak
  export LD_PRELOAD=""
  RD_CFG="$R$HOME/.var/app/net.retrodeck.retrodeck/config/retrodeck/retrodeck.cfg"
  ports_folder="$(retrodeck_cfg_value ports_folder "$RD_CFG")"
  roms_folder="$(retrodeck_cfg_value roms_folder "$RD_CFG")"
  rdhome="$(retrodeck_cfg_value rdhome "$RD_CFG")"
  export controlfolder="$HOME/.var/app/net.retrodeck.retrodeck/data"
  retrodeck_paths

## spruce, TrimUI (and RetroDECK) bundle Volkyport and don't use this installer, they
## are only found so a stray run puts Volkyport where they keep it.
elif [ -d "$R/mnt/SDCARD/spruce" ]; then
  ## spruce
  controlfolder="/mnt/SDCARD/Persistent/volkyport"
  directory="/mnt/SDCARD/Roms"
  OS_NAME_OVERRIDE="spruce"
  NO_FRONTEND_RESTART="Y"

elif [ -d "$R/mnt/SDCARD/Apps/Volkyport" ]; then
  ## TrimUI
  controlfolder="/mnt/SDCARD/Apps/Volkyport"
  directory="/mnt/SDCARD/Data"
  OS_NAME_OVERRIDE="trimui"
  NO_FRONTEND_RESTART="Y"

elif [ -d "$R/userdata/roms/ports" ]; then
  ## Batocera, knulli, REG-Linux
  controlfolder="$XDG_DATA_HOME"
  directory="userdata/roms"
  ## Only a default: knulli's os-release says OS_NAME="knulli" (and so gets knulli/control.txt).
  OS_NAME="batocera"
  BATOCERA_LIKE="Y"

elif [ -d "$R/opt/muos" ] || [ -d "$R/mnt/mmc/MUOS" ]; then
  ## muOS: found, but not installed to, see below.
  controlfolder="/mnt/mmc/MUOS"
  OS_NAME_OVERRIDE="muOS"
  CUR_TTY="${PM_CUR_TTY:-/dev/null}"

elif [ -d "$R/opt/system/Tools" ]; then
  ## ArkOS and friends, the same place as /roms(2)/tools
  controlfolder="/opt/system/Tools"

elif [ -d "$R/opt/tools" ]; then
  ## (harbourmaster checks for /opt/tools/Volkyport, which this is about to create)
  controlfolder="/opt/tools"

else
  ## ROCKNIX, JELOS, AmberELEC, ... (/roms is /storage/roms)
  controlfolder="/roms/ports"
fi

if [ -z "$directory" ]; then
  if [[ -e "$R/usr/share/plymouth/themes/text.plymouth" ]]; then
    if [ ! -z "$(cat "$R/etc/fstab" | grep roms2 | tr -d '\0')" ]; then
      directory="roms2"
    else
      directory="roms"
    fi
  elif [ -d "$R/mnt/sdcard/ROMS/Ports/" ]; then
    directory="/mnt/sdcard/ROMS/"
  elif [ -d "$R/mnt/mmc/ROMS/Ports/" ]; then
    directory="/mnt/mmc/ROMS/"
  else
    directory="roms"
  fi
fi

TEMP_DIR=$(pwd)

if [ -f "$R/etc/os-release" ]; then
  source "$R/etc/os-release"
fi

if [ -n "$OS_NAME_OVERRIDE" ]; then
  OS_NAME="$OS_NAME_OVERRIDE"
fi

if [[ -e "$R/usr/share/plymouth/themes/text.plymouth" ]]; then
  ES_NAME="emulationstation"
elif [ "$BATOCERA_LIKE" = "Y" ]; then
  ES_NAME="batocera-es-swissknife"
else
  ES_NAME="emustation"
fi

if [ "$PM_INSTALL_DETECT" = "Y" ]; then
  echo "controlfolder=$controlfolder"
  echo "directory=$directory"
  echo "OS_NAME=$OS_NAME"
  echo "ES_NAME=$ES_NAME"
  exit 0
fi

## muOS includes Volkyport, with its own way to restore it (or muos.volkyport.zip).
## Don't touch anything there: on muOS releases that read the SD card through
## exfat-fuse (2410 Banana, 2601 Jacaranda), deleting this script while it runs
## crashes the card's driver and every bit of content disappears until a reboot.
if [ "$OS_NAME" = "muOS" ]; then
  echo "muOS includes Volkyport, restore it from muOS or install muos.volkyport.zip. Nothing was changed."
  exit 1
fi

echo "-- Installing on ${OS_NAME:-${PRETTY_NAME:-${NAME:-this device}}} --"

if [ "$NO_SUDO" = "N" ]; then
  if sudo echo "Testing for sudo..." > /dev/null 2>&1; then
    ESUDO="sudo"
  fi
fi

## The launcher moves out of Volkyport/ to where the frontend runs it, except here:
RELOCATE_PM=""
case "${OS_NAME}" in
  JELOS|UnofficialOS|ROCKNIX|retrodeck|spruce|trimui) ;;
  *) RELOCATE_PM="Y" ;;
esac

$ESUDO chmod 666 $CUR_TTY
printf "\033c" > $CUR_TTY

## Everything below needs a working unzip, check it before anything is deleted. (spruce
## put an unzip needing glibc 2.34 first on PATH, and the TrimUI Brick's BusyBox has
## none: the reset went ahead, nothing was unpacked, and it still said "Finished".)
if ! UNZIP_ERROR="$($ESUDO unzip -l "$TEMP_DIR/Volkyport.zip" 2>&1 > /dev/null)"; then
  echo "Unable to read Volkyport.zip with unzip ($(command -v unzip || echo "no unzip found")), nothing was installed:" | tee -a $CUR_TTY
  echo "$UNZIP_ERROR" | tee -a $CUR_TTY
  exit 1
fi

## Everything below works relative to here, never carry on from anywhere else.
$ESUDO mkdir -p "$R$controlfolder"
if ! cd "$R$controlfolder"; then
  echo "Unable to get to $controlfolder, nothing was installed." | tee -a $CUR_TTY
  exit 1
fi

echo "Installing Volkyport to $controlfolder" | tee -a $CUR_TTY

## -- Factory reset: everything goes except the runtimes. ------------------------
$ESUDO mkdir -p temp_runtimes
$ESUDO mv Volkyport/libs/*.squashfs temp_runtimes/ 2>/dev/null

$ESUDO rm -fRv "Volkyport" "Volkyport.sh" | tee -a $CUR_TTY

if [[ "${OS_NAME}" == "JELOS" ]] || [[ "${OS_NAME}" == "ROCKNIX" ]]; then
  ## Taken from this: https://github.com/brooksytech/JELOS/blob/main/packages/apps/volkyport/scripts/start_volkyport.sh
  # Make sure Volkyport exists in .config/Volkyport
  if [ ! -d "$R/storage/.config/Volkyport" ]; then
      mkdir -p "$R/storage/.config/ports/Volkyport"
      cp -rv "$R/usr/config/Volkyport" "$R/storage/.config/"
  fi

  cd "$R/storage/.config/Volkyport" || exit 1

  # Grab the latest Volkyport.sh script and control.txt (newer ROCKNIX has no Volkyport.sh here)
  for config_file in Volkyport.sh control.txt; do
    [ -f "$R/usr/config/Volkyport/$config_file" ] && cp -v "$R/usr/config/Volkyport/$config_file" "$config_file" | tee -a $CUR_TTY
  done

  # Use our gamecontrollerdb.txt
  rm -f gamecontrollerdb.txt
  ln -svf /usr/config/SDL-GameControllerDB/gamecontrollerdb.txt gamecontrollerdb.txt | tee -a $CUR_TTY

  # Use our gptokeyb
  rm -f gptokeyb
  ln -svf /usr/bin/gptokeyb gptokeyb | tee -a $CUR_TTY
  [ -f "$R/usr/config/Volkyport/volkyport.gptk" ] && cp -v "$R/usr/config/Volkyport/volkyport.gptk" volkyport.gptk | tee -a $CUR_TTY

  cd "$R$controlfolder" || exit 1
fi

$ESUDO unzip -o "$TEMP_DIR/Volkyport.zip" | tee -a $CUR_TTY

if [ ! -f "$R$controlfolder/Volkyport/pugwash" ]; then
  ## Don't leave the runtimes stranded in temp_runtimes/, nor carry on as if it worked.
  $ESUDO mkdir -p "$R$controlfolder/Volkyport/libs"
  $ESUDO mv "$R$controlfolder"/temp_runtimes/*.squashfs "$R$controlfolder/Volkyport/libs/" 2>/dev/null
  $ESUDO rm -fR "$R$controlfolder/temp_runtimes/"
  echo "Unpacking Volkyport.zip failed, Volkyport is NOT installed. Run the installer again, or install Volkyport another way." | tee -a $CUR_TTY
  exit 1
fi

## -- This CFW's own launcher and control.txt ------------------------------------
VOLKYPORT_DIR="$R$controlfolder/Volkyport"

if [ ! -z "$OS_NAME" ]; then
  OVERRIDE_DIR="$VOLKYPORT_DIR/${OS_NAME,,}"

  echo "--> $OVERRIDE_DIR <--" | tee -a $CUR_TTY
  if [ -d "$OVERRIDE_DIR" ]; then
    [ -f "$OVERRIDE_DIR/Volkyport.txt" ] && $ESUDO cp -vf "$OVERRIDE_DIR/Volkyport.txt" "$VOLKYPORT_DIR/Volkyport.sh" | tee -a $CUR_TTY
    [ -f "$OVERRIDE_DIR/control.txt"    ] && $ESUDO cp -vf "$OVERRIDE_DIR/control.txt" "$VOLKYPORT_DIR/" | tee -a $CUR_TTY
  fi
fi

if [ ! -z "$RELOCATE_PM" ]; then
  if [ "$BATOCERA_LIKE" = "Y" ]; then
    $ESUDO mv -vf Volkyport/Volkyport.sh "$R/$directory/ports/Volkyport.sh" | tee -a $CUR_TTY
  else
    $ESUDO mv -vf Volkyport/Volkyport.sh Volkyport.sh | tee -a $CUR_TTY
  fi
fi

if [ "$OS_NAME" = "retrodeck" ]; then
  $ESUDO mkdir -p "$R/${roms_folder}/volkyport"
  $ESUDO mv -vf Volkyport/Volkyport.sh "$R/${roms_folder}/volkyport/Volkyport.sh" | tee -a $CUR_TTY
fi

## -- Runtimes: the ones that were here, then the Full installer's. --------------
$ESUDO mv temp_runtimes/*.squashfs Volkyport/libs/ 2>/dev/null
$ESUDO rm -fR temp_runtimes/

if [ -f "$TEMP_DIR/runtimes.zip" ]; then
  cd Volkyport/libs/
  $ESUDO unzip -o "$TEMP_DIR/runtimes.zip" | tee -a $CUR_TTY
  cd "$R$controlfolder" || exit 1
fi

## -- The installer / restore ports have done their job. -------------------------
if [ "$OS_NAME" = "retrodeck" ]; then
  $ESUDO rm -vf "$R/$roms_folder/volkyport/"Install*Volkyport*.sh | tee -a $CUR_TTY
  $ESUDO rm -vf "$R/$roms_folder/volkyport/"Restore*Volkyport*.sh | tee -a $CUR_TTY
else
  $ESUDO rm -vf "$R/$directory/port_scripts/"Install*Volkyport*.sh | tee -a $CUR_TTY
  $ESUDO rm -vf "$R/$directory/port_scripts/"Restore*Volkyport*.sh | tee -a $CUR_TTY
  $ESUDO rm -vf "$R/$directory/ports/"Install*Volkyport*.sh | tee -a $CUR_TTY
  $ESUDO rm -vf "$R/$directory/ports/"Restore*Volkyport*.sh | tee -a $CUR_TTY
fi

echo "Finished installing Volkyport" | tee -a $CUR_TTY
sleep "${PM_INSTALL_SLEEP:-2}"

## -- Let the frontend see the new Volkyport. -----------------------------------
if [ -f "$R$HOME/no_es_restart" ]; then
  $ESUDO rm -f "$R$HOME/no_es_restart"

elif [ -n "$NO_FRONTEND_RESTART" ]; then
  :

elif [ "$OS_NAME" = "ROCKNIX" ]; then
  ## This is for the best.
  chmod -R +x "$R$controlfolder"

  shutdown -r now

elif [[ "$ES_NAME" == "batocera-es-swissknife" ]]; then
  ## Broken
  # batocera-es-swissknife --restart
  curl http://localhost:1234/reloadgames

  chmod -R +x "$R$controlfolder"

  # Install our own shGenerator.py
  SH_GENERATOR="$R/usr/lib/python3.11/site-packages/configgen/generators/sh/shGenerator.py"
  if [ -f "$SH_GENERATOR" ]; then
    if ! grep -q 'gamecontrollerdb.txt' "$SH_GENERATOR"; then
      cp -f "$SH_GENERATOR" "$SH_GENERATOR.bak"

      if ! grep -q 'from generators.Generator import Generator' "$SH_GENERATOR"; then
        # New style relative imports
        cp -f "$VOLKYPORT_DIR/batocera/shGenerator.py" "$SH_GENERATOR"
      else
        # Old style absolute imports
        cp -f "$VOLKYPORT_DIR/knulli/shGenerator.py" "$SH_GENERATOR"
      fi
    fi

    # Newer knulli it is `knulli-save-overlay`, but that is not a concern because it has a different python version.
    batocera-save-overlay
  fi

else
  $ESUDO systemctl restart $ES_NAME
fi
