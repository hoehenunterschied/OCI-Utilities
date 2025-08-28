#!/usr/bin/env bash

NAME=();                 OS=();                       CPU=();
NAME+=('quicktest');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
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
#NAME+=('newol7arm');        OS+=('Oracle Linux 7');      CPU+=('Ampere');
#NAME+=('newol8arm');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
#NAME+=('newol9arm');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
#NAME+=('newol7x86');        OS+=('Oracle Linux 7');      CPU+=('Intel');
#NAME+=('newol8x86');        OS+=('Oracle Linux 8');      CPU+=('Intel');
#NAME+=('newol9x86');        OS+=('Oracle Linux 9');      CPU+=('Intel');
#NAME+=('newol7amd');        OS+=('Oracle Linux 7');      CPU+=('AMD');
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
#SSH_AUTHORIZED_KEYS="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDm41ofwN6PwXN4GYDe/m3LjFt0jPkAdFAY28bfd1eyTN2qn3qVFhbGCVr1BikAo6g9EMzw6c2Kk3UIPQwMRbhxM6B1tcf89XOQaqs7ejJ3E0UQ/c9hhuQydLUA6p2DLg4SOP5DOE8J/UZExD+RMKNc/BUEVFJeSxuhorrzM7LDoHwySzV4Hh216LzpfXe3o23l8XtADwypGLJ4atSKU0m17SpwO1ODdZua00/QROaBtQs0ww7vgPbSlN/j6uxcFChSovg9yU3JBquwyS8fKIWgzahnXnBM0p4mKvmSTgTa8dZ7WdDlIMaJa/X/oNIGxVGUeg/tVeChH4DG9Ww+meB7GsiijkPnhNM29GnD3ziO3Eamwn6dDFrr+WPRL8Xby16kgr1H9QZ93uju3/XmJ5+9tn8Jrtb/rJ65MwwG0NMR0CeOuQl8HR5pNyMvNYTceRVSGLyZJnRbF6dJv+0Vlh4EqhwZiUdyEAMLHyHRokGWfuDLr40MDF/p4EQ5YjkHiYBh7WWvgB3F19QiRBCnmwutfONODxKAdVasbeqRftp/upQU7UfYJknm8It7WMICufAhTOTzwXlhsLA1svyfJnzsKUDjwVnMYvcwvvsj2s9QMEmsNt5WR9YSCfzko53J40xjy65RShXonW+O2RYpWW4A4pefQpy9q/79YIHj58fLlw=="

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
    "user_data": "IyEvdXNyL2Jpbi9lbnYgYmFzaAoKc291cmNlIC9ldGMvb3MtcmVsZWFzZQppZiBbWyAiJE5BTUUiID09ICJPcmFjbGUgTGludXggU2VydmVyIiBdXTsgdGhlbgogIGlmIFtbICIkVkVSU0lPTl9JRCIgPT0gOCogXV07IHRoZW4KICAgIGVjaG8gIk9yYWNsZSBMaW51eCA4IgogICAgc3VkbyBkbmYgaW5zdGFsbCBvcmFjbGVsaW51eC1kZXZlbG9wZXItcmVsZWFzZS1lbDgKICAgIHN1ZG8gZG5mIGluc3RhbGwgb3JhY2xlLWVwZWwtcmVsZWFzZS1lbDgKICAgIHN1ZG8gZG5mIC15IGluc3RhbGwgcHl0aG9uMzYtb2NpLWNsaQogIGVsaWYgW1sgIiRWRVJTSU9OX0lEIiA9PSA5KiBdXTsgdGhlbgogICAgZWNobyAiT3JhY2xlIExpbnV4IDkiCiAgICBzdWRvIGRuZiBpbnN0YWxsIG9yYWNsZWxpbnV4LWRldmVsb3Blci1yZWxlYXNlLWVsOQogICAgc3VkbyBkbmYgaW5zdGFsbCBvcmFjbGUtZXBlbC1yZWxlYXNlLWVsOQogICAgc3VkbyBkbmYgLXkgaW5zdGFsbCBweXRob24zOS1vY2ktY2xpCiAgZWxzZQogICAgZWNobyAiIyMjIHZlcnNpb24gbm90IHN1cHBvcnRlZDogJFZFUlNJT05fSUQiCiAgICBleGl0CiAgZmkKZWxzZQogIGVjaG8gIk9TIG5vdCBzdXBwb3J0ZWQ6ICROQU1FIgogIGV4aXQKZmkKCmV4cG9ydCBPQ0lfQ0xJX0FVVEg9Imluc3RhbmNlX3ByaW5jaXBhbCIKCiMgZG93bmxvYWQgc2NyaXB0cyBmcm9tIG9iamVjdCBzdG9yYWdlCkJVQ0tFVF9OQU1FPSJJbnN0YW5jZVNjcmlwdHMiCk5BTUVTUEFDRT0kKG9jaSBvcyBucyBnZXQgLS1xdWVyeSAiZGF0YSIgfCB0ciAtZCAnIicpCm9jaSBvcyBvYmplY3QgZ2V0IC1ibiAiJHtCVUNLRVRfTkFNRX0iIFwKICAgICAgICAgICAgICAgICAgLW5zICIke05BTUVTUEFDRX0iIFwKICAgICAgICAgICAgICAgICAgLS1maWxlIC90bXAvc2V0dXAuYmFzaCBcCiAgICAgICAgICAgICAgICAgIC0tbmFtZSBzZXR1cC5iYXNoIFwKICAgICYmIGNobW9kIDc1NSAvdG1wL3NldHVwLmJhc2gKCm9jaSBvcyBvYmplY3QgZ2V0IC1ibiAiJHtCVUNLRVRfTkFNRX0iIFwKICAgICAgICAgICAgICAgICAgLW5zICIke05BTUVTUEFDRX0iIFwKICAgICAgICAgICAgICAgICAgLS1maWxlIC90bXAvYm9vdC1pbml0LmJhc2ggXAogICAgICAgICAgICAgICAgICAtLW5hbWUgYm9vdC1pbml0LmJhc2ggXAogICAgJiYgY2htb2QgNzU1IC90bXAvYm9vdC1pbml0LmJhc2gKCi90bXAvYm9vdC1pbml0LmJhc2gKcnVudXNlciAtdSBvcGMgL3RtcC9zZXR1cC5iYXNoCnJ1bnVzZXIgLXUgb3BjCmlkID4gL3RtcC9pZC50eHQK"
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
