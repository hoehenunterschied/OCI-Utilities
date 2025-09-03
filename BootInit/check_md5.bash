#!/usr/bin/env bash

BUCKET_LIST="InstanceScripts"
FILE_LIST=()
FILE_LIST+=('instancectl.bash')
FILE_LIST+=('oci_cli_rc')
FILE_LIST+=('oci-connectivity.bash')
FILE_LIST+=('osmh-logs.bash')
FILE_LIST+=('params.txt')
FILE_LIST+=('register-to-osmh.bash')
FILE_LIST+=('root-setup.bash')
FILE_LIST+=('rpi-connect.bash')
FILE_LIST+=('self-terminate.bash')
FILE_LIST+=('tmux-default.bash')
FILE_LIST+=('unregister-from-osmh.bash')
FILE_LIST+=('user-setup.bash')

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

idiot_counter()
{
   ############################################################
   # force user to type a random string to avoid
   # accidental execution of potentially damaging functions
   ############################################################
   # if tr does not work in the line below, try this:
   #  export STUPID_STRING=$(cat /dev/urandom|LC_ALL=C tr -dc "[:alnum:]"|fold -w 6|head -n 1)
   ############################################################
   export STUPID_STRING="k4JgHrt"
   if [ -e /dev/urandom ];then
     export STUPID_STRING=$(cat /dev/urandom|LC_CTYPE=C tr -dc "[:alnum:]"|fold -w 6|head -n 1)
   fi
   echo -e "#### type \"${STUPID_STRING}\" to approve the above operation ####\n"
   idiot_counter=0
   while true; do
     read line
     case $line in
       ${STUPID_STRING}) break;;
       *)
         idiot_counter=$(($(($idiot_counter+1))%2));
         if [[ $idiot_counter == 0 ]];then
           echo -e "###\n### YOU FAIL !\n###\n### exiting..."; exit;
         fi
         echo "#### type \"${STUPID_STRING}\" to approve the operation above, CTRL-C to abort";
         ;;
     esac
   done
}

OBJECT_LIST="$(oci os object list --all -bn "${BUCKET_LIST}" --query "data[].{name:name,md5:md5}")"

UPTODATE="true"

for FILE in "${FILE_LIST[@]}"; do
  export OBJECT_NAME="${FILE}"
  OBJECT_MD5="$(echo $OBJECT_LIST|jq -r '.[] | select(.name==env.OBJECT_NAME).md5')"
  FILE_MD5="$(openssl dgst -md5 -binary "InstanceScripts/${OBJECT_NAME}" | base64)"
  #printf "%30s %s %s\n" "${OBJECT_NAME}" "${OBJECT_MD5}" "${FILE_MD5}"
  if [[ "${OBJECT_MD5}" != "${FILE_MD5}" ]]; then
    UPTODATE="false"
    printf "%7s %b%s%b\n" "upload" "${RED}" "${OBJECT_NAME}" "${NOCOLOR}"
  else
    printf "%7s %b%s%b\n" "" "${GREEN}" "${OBJECT_NAME}" "${NOCOLOR}"
  fi
done

if [[ "${UPTODATE}" != "true" ]]; then
  printf "continue without uploading changed files to object storage ?\n"
  idiot_counter
  echo "continuing"
fi

