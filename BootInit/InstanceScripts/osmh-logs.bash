#!/usr/bin/env bash

# filename of this script
THIS_SCRIPT="$(basename ${BASH_SOURCE})"
# restart script as sudo if effective user id is not root
if [[ "$EUID" -ne 0 ]]; then
    exec sudo "${BASH_SOURCE}" "$@"
fi

LOG=()
LOG+=('/var/lib/oracle-cloud-agent/plugins/oci-osmh/osmh-agent/stateDir/log/osmh-agent.log')
LOG+=('/var/log/oracle-cloud-agent/plugins/oci-osmh/oci-osmh.log')
LOG+=('/var/log/oracle-cloud-agent/agent.log')

# ----------------------------------
# Colors
# ----------------------------------
NOCOLOR='\x1B[0m'
RED='\x1B[0;31m'
GREEN='\x1B[0;32m'
ORANGE='\x1B[0;33m'
BLUE='\x1B[0;34m'
PURPLE='\x1B[0;35m'
CYAN='\x1B[0;36m'
LIGHTGRAY='\x1B[0;37m'
DARKGRAY='\x1B[1;30m'
LIGHTRED='\x1B[1;31m'
LIGHTGREEN='\x1B[1;32m'
YELLOW='\x1B[1;33m'
LIGHTBLUE='\x1B[1;34m'
LIGHTPURPLE='\x1B[1;35m'
LIGHTCYAN='\x1B[1;36m'
WHITE='\x1B[1;37m'

WATCHLIST=()
for log in "${LOG[@]}"; do
  if [[ -s "${log}" ]]; then
    echo -e "${GREEN}${log}${NOCOLOR}"
    WATCHLIST+=("${log}")
  else
    echo -e "${RED}${log}${NOCOLOR}"
  fi
done
if [ ${#WATCHLIST[@]} -eq 0 ]; then
  exit
fi
for log in "${WATCHLIST[@]}"; do
  sudo less "${log}"
done
