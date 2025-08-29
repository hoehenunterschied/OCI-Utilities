#!/usr/bin/env bash

NAME=(); OS=(); CPU=();
NAME+=('quicktest');     OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('crashandburn');  OS+=('Oracle Linux 9');      CPU+=('Ampere');

#NAME+=('frankfurt');     OS+=('Oracle Linux 9');      CPU+=('Ampere');

#NAME+=('brahms');   OS+=('Oracle Linux 8'); CPU+=('AMD');
#NAME+=('mahler');   OS+=('Oracle Linux 8'); CPU+=('AMD');
#NAME+=('dvorak');   OS+=('Oracle Linux 8'); CPU+=('AMD');
#NAME+=('haydn');    OS+=('Oracle Linux 8'); CPU+=('AMD');
#NAME+=('schubert'); OS+=('Oracle Linux 8'); CPU+=('AMD');
#NAME+=('wagner');   OS+=('Oracle Linux 8'); CPU+=('AMD');
#NAME+=('liszt');    OS+=('Oracle Linux 8'); CPU+=('AMD');
#NAME+=('vivaldi');  OS+=('Oracle Linux 8'); CPU+=('AMD');
#NAME+=('chopin');   OS+=('Oracle Linux 8'); CPU+=('AMD');

#NAME+=('ol9arm1');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('ol9arm2');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('ol9arm3');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('ol9arm4');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('ol9arm5');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('ol8arm1');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('ol8arm2');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('ol8arm3');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('ol8arm4');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('ol8arm5');        OS+=('Oracle Linux 8');      CPU+=('Ampere');

#NAME+=('newol8arm');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('newol9arm');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('newol8x86');        OS+=('Oracle Linux 8');      CPU+=('Intel');
#NAME+=('newol9x86');        OS+=('Oracle Linux 9');      CPU+=('Intel');
#NAME+=('newol8amd');        OS+=('Oracle Linux 8');      CPU+=('AMD');
#NAME+=('newol9amd');        OS+=('Oracle Linux 9');      CPU+=('AMD');
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


########################################

# get tenancy id
TENANCY_ID=$(oci --cli-rc-file /dev/null iam availability-domain list --query "data[*].\"compartment-id\" | [0]" | tr -d '"')
echo "         TENANCY_ID : $TENANCY_ID"

# get compartment id
COMPARTMENT_ID=$(oci --cli-rc-file /dev/null iam compartment list --all --compartment-id "$TENANCY_ID" --compartment-id-in-subtree true --query "data[?name=='${COMPARTMENT_NAME}'].id | [0]" | tr -d '"')
echo "     COMPARTMENT_ID : $COMPARTMENT_ID"

# get availability domain
AVAILABILITY_DOMAIN=$(oci --cli-rc-file /dev/null iam availability-domain list --query "data[*].name | [$(($AVAILABILITY_DOMAIN_NUMBER - 1))]" | tr -d '"')
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
    "user_data": "IyEvdXNyL2Jpbi9lbnYgYmFzaAojIGNvbnZlcnQgdGhpcyBmaWxlIHdpdGgKIyAgY2F0IDxmaWxlbmFtZT4gfCBiYXNlNjQgLS13cmFwIDAKIyBhbmQgcHV0IGl0IGFzIHVzZXJfZGF0YSBpbiB0aGUgbGF1bmNoIHNjcmlwdApleGVjID4gL3RtcC9ib290LWluaXQtb3V0cHV0LnR4dCAyPiYxCgpzb3VyY2UgL2V0Yy9vcy1yZWxlYXNlCmlmIFtbICIkTkFNRSIgPT0gIk9yYWNsZSBMaW51eCBTZXJ2ZXIiIF1dOyB0aGVuCiAgaWYgW1sgIiRWRVJTSU9OX0lEIiA9PSA4KiBdXTsgdGhlbgogICAgZWNobyAiT3JhY2xlIExpbnV4IDgiCiAgICBkbmYgLXkgaW5zdGFsbCBweXRob24zNi1vY2ktY2xpCiAgZWxpZiBbWyAiJFZFUlNJT05fSUQiID09IDkqIF1dOyB0aGVuCiAgICBlY2hvICJPcmFjbGUgTGludXggOSIKICAgIGRuZiAteSBpbnN0YWxsIHB5dGhvbjM5LW9jaS1jbGkKICBlbHNlCiAgICBlY2hvICIjIyMgdmVyc2lvbiBub3Qgc3VwcG9ydGVkOiAkVkVSU0lPTl9JRCIKICAgIGV4aXQKICBmaQplbHNlCiAgZWNobyAiT1Mgbm90IHN1cHBvcnRlZDogJE5BTUUiCiAgZXhpdApmaQoKZXhwb3J0IE9DSV9DTElfQVVUSD0iaW5zdGFuY2VfcHJpbmNpcGFsIgoKIyBkb3dubG9hZCBzY3JpcHRzIGZyb20gb2JqZWN0IHN0b3JhZ2UKQlVDS0VUX05BTUU9Ikluc3RhbmNlU2NyaXB0cyIKTkFNRVNQQUNFPSQob2NpIG9zIG5zIGdldCAtLXF1ZXJ5ICJkYXRhIiB8IHRyIC1kICciJykKb2NpIG9zIG9iamVjdCBnZXQgLWJuICIke0JVQ0tFVF9OQU1FfSIgXAogICAgICAgICAgICAgICAgICAtbnMgIiR7TkFNRVNQQUNFfSIgXAogICAgICAgICAgICAgICAgICAtLWZpbGUgL3RtcC9yb290LXNldHVwLmJhc2ggXAogICAgICAgICAgICAgICAgICAtLW5hbWUgcm9vdC1zZXR1cC5iYXNoIFwKICAgICYmIGNobW9kIDc1NSAvdG1wL3Jvb3Qtc2V0dXAuYmFzaAoKb2NpIG9zIG9iamVjdCBnZXQgLWJuICIke0JVQ0tFVF9OQU1FfSIgXAogICAgICAgICAgICAgICAgICAtbnMgIiR7TkFNRVNQQUNFfSIgXAogICAgICAgICAgICAgICAgICAtLWZpbGUgL3RtcC91c2VyLXNldHVwLmJhc2ggXAogICAgICAgICAgICAgICAgICAtLW5hbWUgdXNlci1zZXR1cC5iYXNoIFwKICAgICYmIGNobW9kIDc1NSAvdG1wL3VzZXItc2V0dXAuYmFzaAoKL3RtcC9yb290LXNldHVwLmJhc2gKcnVudXNlciAtdSBvcGMgL3RtcC91c2VyLXNldHVwLmJhc2gKcnVudXNlciAtdSBvcGMgaWQgPiAvdG1wL2lkLnR4dAo="
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
  #echo "     NOT: $NOT"
  #echo "      OS: $OS"
  #echo "   SHAPE: $SHAPE"
  #echo -e "IMAGE_ID: ${IMAGE_ID}\n"
  launch_instance "${NAME[$i]}"
done
exit

# Check if at least one name is passed
if [ "$#" -lt 1 ]; then
  echo "Usage: $THIS_SCRIPT name1 [name2 ...]"
  exit 1
fi

# Iterate over each name
for arg in "$@"; do
  echo -e "\n########################################"
  echo "### Create Instance \"$arg\""
  launch_instance "$arg"
done
