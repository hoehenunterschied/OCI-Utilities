#!/usr/bin/env bash

NAME=(); OS=(); CPU=();
NAME+=('new');  OS+=('Oracle Linux 10');      CPU+=('Ampere');
#NAME+=('crashandburn');  OS+=('Oracle Linux 10');      CPU+=('Ampere');
#NAME+=('quicktest');     OS+=('Oracle Linux 9');      CPU+=('Ampere');

#NAME+=('frankfurt');     OS+=('Oracle Linux 9');      CPU+=('Ampere');

#NAME+=('brahms');   OS+=('Oracle Linux 9'); CPU+=('AMD');
#NAME+=('mahler');   OS+=('Oracle Linux 9'); CPU+=('AMD');
#NAME+=('dvorak');   OS+=('Oracle Linux 9'); CPU+=('AMD');
#NAME+=('haydn');    OS+=('Oracle Linux 9'); CPU+=('AMD');
#NAME+=('schubert'); OS+=('Oracle Linux 9'); CPU+=('AMD');
#NAME+=('wagner');   OS+=('Oracle Linux 9'); CPU+=('AMD');
#NAME+=('liszt');    OS+=('Oracle Linux 9'); CPU+=('AMD');
#NAME+=('vivaldi');  OS+=('Oracle Linux 9'); CPU+=('AMD');
#NAME+=('chopin');   OS+=('Oracle Linux 9'); CPU+=('AMD');

#NAME+=('ol9arm1');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('ol9arm2');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('ol9arm3');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('ol8arm1');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('ol8arm2');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('ol8arm3');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('ol10arm1');       OS+=('Oracle Linux 10');     CPU+=('Ampere');
#NAME+=('ol10arm2');       OS+=('Oracle Linux 10');     CPU+=('Ampere');
#NAME+=('ol10arm3');       OS+=('Oracle Linux 10');     CPU+=('Ampere');

#NAME+=('newol8arm');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('newol9arm');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('newol10arm');       OS+=('Oracle Linux 10');     CPU+=('Ampere');
#NAME+=('newol8x86');        OS+=('Oracle Linux 8');      CPU+=('Intel');
#NAME+=('newol9x86');        OS+=('Oracle Linux 9');      CPU+=('Intel');
#NAME+=('newol10x86');       OS+=('Oracle Linux 10');     CPU+=('Intel');
#NAME+=('newol8amd');        OS+=('Oracle Linux 8');      CPU+=('AMD');
#NAME+=('newol9amd');        OS+=('Oracle Linux 9');      CPU+=('AMD');
#NAME+=('newol10amd');       OS+=('Oracle Linux 10');     CPU+=('AMD');
# Windows not yet implemented
#NAME+=('win2016x86');    OS+=('Windows Server 2016'); CPU+=('Intel');
#NAME+=('win2019x86');    OS+=('Windows Server 2019'); CPU+=('Intel');
#NAME+=('win2022x86');    OS+=('Windows Server 2022'); CPU+=('Intel');
#NAME+=('win2016amd');    OS+=('Windows Server 2016'); CPU+=('AMD');
#NAME+=('win2019amd');    OS+=('Windows Server 2019'); CPU+=('AMD');
#NAME+=('win2022amd');    OS+=('Windows Server 2022'); CPU+=('AMD');

OCPUS="1.0"
MEMORY_IN_GBS="6.0"
COMPARTMENT_NAME="Ralf_lange"
VCN_NAME="MainNet"
SUBNET_NAME="public"
# AVAILABILITY_DOMAIN_NUMBER must be 1 in single availability domain regions,
#    can be one of 1, 2 or 3 in multi availability domain regions
AVAILABILITY_DOMAIN_NUMBER="3"
SSH_AUTHORIZED_KEYS_FILE="ssh_authorized_keys"

# cd to the directory this script is in
cd "$(dirname "$(realpath "$0")")"


#######################################################################
echo "### check if files in InstanceScripts bucket differ from local files"
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

OBJECT_LIST="$(oci os object list --all -bn InstanceScripts --query "data[].{name:name,md5:md5}")"

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
#######################################################################

# get tenancy id
if TENANCY_ID="$(curl --connect-timeout 3 -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/tenantId)"; then
  echo "inside OCI instance"
else
  TENANCY_ID=$(oci --cli-rc-file /dev/null iam availability-domain list --query "data[*].\"compartment-id\" | [0]" | tr -d '"')
fi
echo "         TENANCY_ID : $TENANCY_ID"

# get compartment id
COMPARTMENT_ID=$(oci --cli-rc-file /dev/null iam compartment list --all --compartment-id "$TENANCY_ID" --compartment-id-in-subtree true --query "data[?name=='${COMPARTMENT_NAME}'].id | [0]" | tr -d '"')
echo "     COMPARTMENT_ID : $COMPARTMENT_ID"

# get availability domain
AVAILABILITY_DOMAIN=$(oci --cli-rc-file /dev/null iam availability-domain list --compartment-id "${COMPARTMENT_ID}" --query "data[*].name | [$(($AVAILABILITY_DOMAIN_NUMBER - 1))]" | tr -d '"')
echo "AVAILABILITY_DOMAIN : $AVAILABILITY_DOMAIN"

# get VCN id
VCN_ID=$(oci --cli-rc-file /dev/null network vcn list --compartment-id "${COMPARTMENT_ID}" --query "data[?\"display-name\"=='${VCN_NAME}'].id | [0]" | tr -d '"')
echo "             VCN_ID : $VCN_ID"

# get subnet id
SUBNET_ID=$(oci --cli-rc-file /dev/null network subnet list --compartment-id "${COMPARTMENT_ID}" --vcn-id "${VCN_ID}" --query "data[?\"display-name\"=='${SUBNET_NAME}'].id | [0]" | tr -d '"')
echo "          SUBNET_ID : $SUBNET_ID"

# filename of this script
THIS_SCRIPT="$(basename ${BASH_SOURCE})"

launch_instance()
{
  tempfile=$(mktemp)
  echo "Temporary file created: $tempfile"
  
  cat > "${tempfile}" << EOF
{
  "availabilityDomain": "${AVAILABILITY_DOMAIN}",
  "compartmentId": "${COMPARTMENT_ID}",
  "sshAuthorizedKeysFile": "${SSH_AUTHORIZED_KEYS_FILE}",
  "displayName": "$1",
  "shape": "${SHAPE}",
  "shapeConfig": {
    "memoryInGBs": "${MEMORY_IN_GBS}",
    "ocpus": "${OCPUS}"
  },
  "sourceDetails": {
    "sourceType": "image",
    "imageId": "${IMAGE_ID}"
  },
  "createVnicDetails": {
    "subnetId": "${SUBNET_ID}",
    "assignPublicIp": true,
    "hostnameLabel": "$1"
  },
  "metadata": {
    "user_data": "$(cat boot-init.bash | base64 --wrap 0)"
  }
}
EOF
  
  oci --cli-rc-file /dev/null compute instance launch --compartment-id "${COMPARTMENT_ID}" --subnet-id "${SUBNET_ID}" --from-json file://"${tempfile}" && rm "${tempfile}"
}

for i in "${!NAME[@]}"; do
  #printf "NAME: %10s    OS: %19s    CPU: %6s\n" "${NAME[$i]}" "${OS[$i]}" "${CPU[$i]}"
  printf "%10s  %-6s  %-19s\n" "${NAME[$i]}" "${CPU[$i]}" "${OS[$i]}"
  case "${OS[$i]}" in
    "Oracle Linux 7")
      OS="Oracle-Linux-7"
      ;;
    "Oracle Linux 8")
      OS="Oracle-Linux-8"
      ;;
    "Oracle Linux 9")
      OS="Oracle-Linux-9"
      ;;
    "Oracle Linux 10")
      OS="Oracle-Linux-10"
      ;;
  esac
  case "${CPU[$i]}" in
    "Ampere")
      NOT=""
      if [ "${OS}" = "Oracle-Linux-7"  ]; then
        SHAPE="VM.Standard.A1.Flex"
      else
        SHAPE="VM.Standard.A2.Flex"
      fi
      ;;
    "AMD")
      NOT="!"
      SHAPE="VM.Standard.E4.Flex"
      ;;
    "Intel")
      NOT="!"
      SHAPE="VM.Optimized3.Flex"
      ;;
  esac 
  IMAGE_ID=$(oci compute image list --all --query "data[?starts_with(\"display-name\", '$OS') && $NOT contains(\"display-name\", 'aarch64') && ! contains(\"display-name\", 'GPU') && ! contains(\"display-name\", 'Minimal')]|sort_by(@, &\"time-created\")[-1].\"id\"" --all | tr -d '"')
  #echo "oci compute image list --all --query \"data[?starts_with(\\\"display-name\\\", '$OS') && $NOT contains(\\\"display-name\\\", 'aarch64') && ! contains(\\\"display-name\\\", 'GPU') && ! contains(\\\"display-name\\\", 'Minimal')]|sort_by(@, &\\\"time-created\\\")[-1].\\\"display-name\\\"\" --all"
  #echo "     NOT: $NOT"
  #echo "      OS: $OS"
  #echo "   SHAPE: $SHAPE"
  #echo -e "IMAGE_ID: ${IMAGE_ID}\n"
  launch_instance "${NAME[$i]}"
done

