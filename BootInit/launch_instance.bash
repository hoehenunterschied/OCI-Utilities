#!/usr/bin/env bash

NAME=();                 OS=();                       CPU=();
NAME+=('crashandburn');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
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
    "user_data": "IyEvdXNyL2Jpbi9lbnYgYmFzaAojIGNvbnZlcnQgdGhpcyBmaWxlIHdpdGgKIyAgY2F0IDxmaWxlbmFtZT4gfCBiYXNlNjQgLS13cmFwIDAKIyBhbmQgcHV0IGl0IGFzIHVzZXJfZGF0YSBpbiB0aGUgbGF1bmNoIHNjcmlwdAoKc291cmNlIC9ldGMvb3MtcmVsZWFzZQppZiBbWyAiJE5BTUUiID09ICJPcmFjbGUgTGludXggU2VydmVyIiBdXTsgdGhlbgogIGlmIFtbICIkVkVSU0lPTl9JRCIgPT0gOCogXV07IHRoZW4KICAgIGVjaG8gIk9yYWNsZSBMaW51eCA4IgogICAgZG5mIGluc3RhbGwgb3JhY2xlbGludXgtZGV2ZWxvcGVyLXJlbGVhc2UtZWw4CiAgICBkbmYgaW5zdGFsbCBvcmFjbGUtZXBlbC1yZWxlYXNlLWVsOAogICAgZG5mIC15IGNvbmZpZy1tYW5hZ2VyIC0tZW5hYmxlIG9sOF9kZXZlbG9wZXJfRVBFTAogICAgZG5mIC15IGluc3RhbGwgcHl0aG9uMzYtb2NpLWNsaQogIGVsaWYgW1sgIiRWRVJTSU9OX0lEIiA9PSA5KiBdXTsgdGhlbgogICAgZWNobyAiT3JhY2xlIExpbnV4IDkiCiAgICBkbmYgaW5zdGFsbCBvcmFjbGVsaW51eC1kZXZlbG9wZXItcmVsZWFzZS1lbDkKICAgIGRuZiBpbnN0YWxsIG9yYWNsZS1lcGVsLXJlbGVhc2UtZWw5CiAgICBkbmYgLXkgY29uZmlnLW1hbmFnZXIgLS1lbmFibGUgb2w5X2RldmVsb3Blcl9FUEVMCiAgICBkbmYgLXkgaW5zdGFsbCBweXRob24zOS1vY2ktY2xpCiAgZWxzZQogICAgZWNobyAiIyMjIHZlcnNpb24gbm90IHN1cHBvcnRlZDogJFZFUlNJT05fSUQiCiAgICBleGl0CiAgZmkKZWxzZQogIGVjaG8gIk9TIG5vdCBzdXBwb3J0ZWQ6ICROQU1FIgogIGV4aXQKZmkKCiMgaW5zdGFsbCB0bXV4LCBnaXQsIGh0b3AgYW5kIEV0ZXJuYWwgVGVybWluYWwKZG5mIC15IGluc3RhbGwgdG11eCBnaXQgaHRvcCBldApzeXN0ZW1jdGwgLS1ub3cgZW5hYmxlIGV0CmZpcmV3YWxsLWNtZCAtLXBlcm1hbmVudCAtLXpvbmU9cHVibGljIC0tYWRkLXBvcnQ9MjAyMi90Y3AKCklOU1RBTkNFX05BTUU9IiQoY3VybCAtcyAtSCAiQXV0aG9yaXphdGlvbjogQmVhcmVyIE9yYWNsZSIgaHR0cDovLzE2OS4yNTQuMTY5LjI1NC9vcGMvdjIvaW5zdGFuY2UvZGlzcGxheU5hbWUpIgppZiBbICIke0lOU1RBTkNFX05BTUV9IiA9ICJmcmFua2Z1cnQiIF07IHRoZW4KICBkbmYgLXkgaW5zdGFsbCBodHRwZAogIHN5c3RlbWN0bCAtLW5vdyBlbmFibGUgaHR0cGQKICBmaXJld2FsbC1jbWQgLS1wZXJtYW5lbnQgLS16b25lPXB1YmxpYyAtLWFkZC1wb3J0PTgwL3RjcApmaQpmaXJld2FsbC1jbWQgLS1yZWxvYWQKCmV4cG9ydCBPQ0lfQ0xJX0FVVEg9Imluc3RhbmNlX3ByaW5jaXBhbCIKCiMgZG93bmxvYWQgc2NyaXB0cyBmcm9tIG9iamVjdCBzdG9yYWdlCkJVQ0tFVF9OQU1FPSJJbnN0YW5jZVNjcmlwdHMiCk5BTUVTUEFDRT0kKG9jaSBvcyBucyBnZXQgLS1xdWVyeSAiZGF0YSIgfCB0ciAtZCAnIicpCm9jaSBvcyBvYmplY3QgZ2V0IC1ibiAiJHtCVUNLRVRfTkFNRX0iIFwKICAgICAgICAgICAgICAgICAgLW5zICIke05BTUVTUEFDRX0iIFwKICAgICAgICAgICAgICAgICAgLS1maWxlIC90bXAvdXNlci1zZXR1cC5iYXNoIFwKICAgICAgICAgICAgICAgICAgLS1uYW1lIHVzZXItc2V0dXAuYmFzaCBcCiAgICAmJiBjaG1vZCA3NTUgL3RtcC91c2VyLXNldHVwLmJhc2gKCnJ1bnVzZXIgLXUgb3BjIC90bXAvdXNlci1zZXR1cC5iYXNoCnJ1bnVzZXIgLXUgb3BjIGlkID4gL3RtcC9pZC50eHQK"
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
