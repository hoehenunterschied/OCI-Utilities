#!/usr/bin/env bash

NAME=();                 OS=();                       CPU=();
NAME+=('newol7arm');        OS+=('Oracle Linux 7');      CPU+=('Ampere');
NAME+=('newol8arm');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
NAME+=('newol9arm');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
NAME+=('newol7x86');        OS+=('Oracle Linux 7');      CPU+=('Intel');
NAME+=('newol8x86');        OS+=('Oracle Linux 8');      CPU+=('Intel');
NAME+=('newol9x86');        OS+=('Oracle Linux 9');      CPU+=('Intel');
NAME+=('newol7amd');        OS+=('Oracle Linux 7');      CPU+=('AMD');
NAME+=('newol8amd');        OS+=('Oracle Linux 8');      CPU+=('AMD');
NAME+=('newol9amd');        OS+=('Oracle Linux 9');      CPU+=('AMD');
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
SSH_AUTHORIZED_KEYS="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDm41ofwN6PwXN4GYDe/m3LjFt0jPkAdFAY28bfd1eyTN2qn3qVFhbGCVr1BikAo6g9EMzw6c2Kk3UIPQwMRbhxM6B1tcf89XOQaqs7ejJ3E0UQ/c9hhuQydLUA6p2DLg4SOP5DOE8J/UZExD+RMKNc/BUEVFJeSxuhorrzM7LDoHwySzV4Hh216LzpfXe3o23l8XtADwypGLJ4atSKU0m17SpwO1ODdZua00/QROaBtQs0ww7vgPbSlN/j6uxcFChSovg9yU3JBquwyS8fKIWgzahnXnBM0p4mKvmSTgTa8dZ7WdDlIMaJa/X/oNIGxVGUeg/tVeChH4DG9Ww+meB7GsiijkPnhNM29GnD3ziO3Eamwn6dDFrr+WPRL8Xby16kgr1H9QZ93uju3/XmJ5+9tn8Jrtb/rJ65MwwG0NMR0CeOuQl8HR5pNyMvNYTceRVSGLyZJnRbF6dJv+0Vlh4EqhwZiUdyEAMLHyHRokGWfuDLr40MDF/p4EQ5YjkHiYBh7WWvgB3F19QiRBCnmwutfONODxKAdVasbeqRftp/upQU7UfYJknm8It7WMICufAhTOTzwXlhsLA1svyfJnzsKUDjwVnMYvcwvvsj2s9QMEmsNt5WR9YSCfzko53J40xjy65RShXonW+O2RYpWW4A4pefQpy9q/79YIHj58fLlw=="



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
    "ssh_authorized_keys": "${SSH_AUTHORIZED_KEYS}",
    "user_data": "IyEvdXNyL2Jpbi9lbnYgYmFzaAoKVVNFUl9IT01FPSIvaG9tZS9vcGMiClVTRVJBTkRHUk9VUD0ib3BjOm9wYyIKVE1VWF9TQ1JJUFQ9InRtdXgtZGVmYXVsdC5iYXNoIgpMRVNTX1NDUklQVD0ib3NtaC1sb2dzLmJhc2giCk9DSV9DT05ORUNUSVZJVFlfU0NSSVBUPSJvY2ktY29ubmVjdGl2aXR5LmJhc2giCgojIGRldGVybWluZSBvcGVyYXRpbmcgc3lzdGVtIHZlcnNpb24KaWYgWyAtZiAvZXRjL29yYWNsZS1yZWxlYXNlIF07IHRoZW4KICAgIHJlbGVhc2VfaW5mbz0kKGNhdCAvZXRjL29yYWNsZS1yZWxlYXNlKQplbGlmIFsgLWYgL2V0Yy9vcy1yZWxlYXNlIF07IHRoZW4KICAgIHJlbGVhc2VfaW5mbz0kKGdyZXAgJ15WRVJTSU9OX0lEPScgL2V0Yy9vcy1yZWxlYXNlIHwgY3V0IC1kPSAtZjIgfCB0ciAtZCAnIicpCmVsc2UKICAgIGVjaG8gIkNhbm5vdCBkZXRlcm1pbmUgT3JhY2xlIExpbnV4IHZlcnNpb24iCmZpCgppZiBbWyAiJHJlbGVhc2VfaW5mbyIgPT0gKiI3LiIqIHx8ICIkcmVsZWFzZV9pbmZvIiA9PSAiNyIgXV07IHRoZW4KICAgIGNhdCA+IC9ldGMveXVtLnJlcG9zLmQvZXBlbC15dW0tb2w3LnJlcG8gPDwgRU9GCltvbDdfZXBlbF0KbmFtZT1PcmFjbGUgTGludXggXCRyZWxlYXNldmVyIEVQRUwgKFwkYmFzZWFyY2gpCmJhc2V1cmw9aHR0cDovL3l1bS5vcmFjbGUuY29tL3JlcG8vT3JhY2xlTGludXgvT0w3L2RldmVsb3Blcl9FUEVML1wkYmFzZWFyY2gvCmdwZ2tleT1maWxlOi8vL2V0Yy9wa2kvcnBtLWdwZy9SUE0tR1BHLUtFWS1vcmFjbGUKZ3BnY2hlY2s9MQplbmFibGVkPTEKRU9GCiAgICB5dW0gaW5zdGFsbCAteSB0bXV4IGdpdCBodG9wCmVsaWYgW1sgIiRyZWxlYXNlX2luZm8iID09ICoiOC4iKiB8fCAiJHJlbGVhc2VfaW5mbyIgPT0gIjgiIF1dOyB0aGVuCiAgICBlY2hvICJPcmFjbGUgTGludXggOCBkZXRlY3RlZCIKICAgIGRuZiAteSBjb25maWctbWFuYWdlciAtLWVuYWJsZSBvbDhfZGV2ZWxvcGVyX0VQRUwKICAgIGRuZiAteSBpbnN0YWxsIHRtdXggZ2l0IGh0b3AKZWxpZiBbWyAiJHJlbGVhc2VfaW5mbyIgPT0gKiI5LiIqIHx8ICIkcmVsZWFzZV9pbmZvIiA9PSAiOSIgXV07IHRoZW4KICAgIGRuZiAteSBjb25maWctbWFuYWdlciAtLWVuYWJsZSBvbDlfZGV2ZWxvcGVyX0VQRUwKICAgIGRuZiAteSBpbnN0YWxsIHRtdXggZ2l0IGh0b3AKZWxzZQogICAgZWNobyAiVW5rbm93biBvciB1bnN1cHBvcnRlZCBPcmFjbGUgTGludXggdmVyc2lvbjogJHJlbGVhc2VfaW5mbyIKZmkKCgpzZWQgLS1pbi1wbGFjZT0uYmFrIC1lICdzL1wkSE9NRVwvYmluLyRIT01FXC8uYmluLycgIiR7VVNFUl9IT01FfSIvLmJhc2hyYwpta2RpciAiJHtVU0VSX0hPTUV9Ly5iaW4iICYmIGNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy5iaW4KCmNhdCA+ICIke1VTRVJfSE9NRX0vLmJpbi8ke1RNVVhfU0NSSVBUfSIgPDwgRU9GCiMhL3Vzci9iaW4vZW52IGJhc2gKaWYgWyAhIC1kICJcJHtIT01FfS90bXAiIF07IHRoZW4KICBta2RpciAiXCR7SE9NRX0vdG1wIgpmaQpjZCAiXCR7SE9NRX0vdG1wIgp0bXV4IGhhcy1zZXNzaW9uIC10ICJcJChob3N0bmFtZSkiICYmIHRtdXggYXR0YWNoLXNlc3Npb24gLXQgIlwkKGhvc3RuYW1lKSIgfHwgdG11eCBuZXctc2Vzc2lvbiAtcyAiXCQoaG9zdG5hbWUpIlw7IFxcCiAgICAgc3BsaXQtd2luZG93IC1oIFw7IFxcCiAgICAgc2VuZC1rZXlzICdodG9wJyBDLW1cOyBcXAogICAgIHNwbGl0LXdpbmRvdyAtdlw7IFxcCiAgICAgc2VsZWN0LXBhbmUgLXQgMVw7CkVPRgpjaG1vZCB1Zyt4ICIke1VTRVJfSE9NRX0iLy5iaW4vIiR7VE1VWF9TQ1JJUFR9IgpjaG93biAiJHtVU0VSQU5ER1JPVVB9IiAiJHtVU0VSX0hPTUV9Ii8uYmluLyIke1RNVVhfU0NSSVBUfSIKCmNhdCA+PiAiJHtVU0VSX0hPTUV9Ii8uYmFzaF9wcm9maWxlIDw8IEVPRgppZiBbWyAteiBcJFRNVVggXV0gJiYgW1sgLW4gXCRTU0hfVFRZIF1dOyB0aGVuCgkgICJcJHtIT01FfSIvLmJpbi8iJHtUTVVYX1NDUklQVH0iCmZpCkVPRgoKY2F0ID4gIiR7VVNFUl9IT01FfS8uYmluLyR7TEVTU19TQ1JJUFR9IiA8PCBFT0YKIyEvdXNyL2Jpbi9lbnYgYmFzaApzdWRvIGxlc3MgXFwKICAvdmFyL2xpYi9vcmFjbGUtY2xvdWQtYWdlbnQvcGx1Z2lucy9vY2ktb3NtaC9vc21oLWFnZW50L3N0YXRlRGlyL2xvZy9vc21oLWFnZW50LmxvZyBcXAogIC92YXIvbG9nL29yYWNsZS1jbG91ZC1hZ2VudC9wbHVnaW5zL29jaS1vc21oL29jaS1vc21oLmxvZyBcXAogIC92YXIvbG9nL29yYWNsZS1jbG91ZC1hZ2VudC9hZ2VudC5sb2cKRU9GCmNobW9kIHVnK3ggIiR7VVNFUl9IT01FfSIvLmJpbi8iJHtMRVNTX1NDUklQVH0iCmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy5iaW4vIiR7TEVTU19TQ1JJUFR9IgoKY2F0ID4gIiR7VVNFUl9IT01FfS8uYmluLyR7T0NJX0NPTk5FQ1RJVklUWV9TQ1JJUFR9IiA8PCBFT0YKIyEvdXNyL2Jpbi9lbnYgYmFzaAoKdGVtcGZpbGU9XCQobWt0ZW1wKQplY2hvICJUZW1wb3JhcnkgZmlsZSBjcmVhdGVkOiBcJHRlbXBmaWxlIgoKY3VybCAtcyAtSCAiQXV0aG9yaXphdGlvbjogQmVhcmVyIE9yYWNsZSIgaHR0cDovLzE2OS4yNTQuMTY5LjI1NC9vcGMvdjIvaW5zdGFuY2UvcmVnaW9uSW5mbyA+ICJcJHt0ZW1wZmlsZX0iCmV4cG9ydCBSRUdJT049XCQoY2F0ICJcJHt0ZW1wZmlsZX0iIHwganEgLXIgIi5yZWdpb25JZGVudGlmaWVyIikKZXhwb3J0IERPTUFJTj1cJChjYXQgIlwke3RlbXBmaWxlfSIgfCBqcSAtciAiLnJlYWxtRG9tYWluQ29tcG9uZW50IikKY3VybCAtcyBodHRwczovL29zbWguIlwke1JFR0lPTn0iLm9jaS4iXCR7RE9NQUlOfSIgJj4vZGV2L251bGwgOyBbIFwkPyA9PSAwIF0gJiYgZWNobyAiU3VjY2VzcyIgfHwgZWNobyAiRmFpbHVyZSIKcm0gIlwke3RlbXBmaWxlfSIKRU9GCmNobW9kIHVnK3ggIiR7VVNFUl9IT01FfSIvLmJpbi8iJHtPQ0lfQ09OTkVDVElWSVRZX1NDUklQVH0iCmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy5iaW4vIiR7T0NJX0NPTk5FQ1RJVklUWV9TQ1JJUFR9IgoKY2QgIiR7VVNFUl9IT01FfSIKZ2l0IGNsb25lIC0tc2luZ2xlLWJyYW5jaCBodHRwczovL2dpdGh1Yi5jb20vZ3Bha29zei8udG11eC5naXQKbG4gLXMgLWYgLnRtdXgvLnRtdXguY29uZgpjcCAudG11eC8udG11eC5jb25mLmxvY2FsIC4Kc2VkIC0taW4tcGxhY2U9LmJhayAtZSAncy9eI3NldCAtZyBtb3VzZSBvbi9zZXQgLWcgbW91c2Ugb24vJyAiJHtVU0VSX0hPTUV9Ii8udG11eC5jb25mLmxvY2FsCmNob3duIC1SICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy50bXV4CmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy50bXV4LmNvbmYKY2hvd24gIiR7VVNFUkFOREdST1VQfSIgIiR7VVNFUl9IT01FfSIvLnRtdXguY29uZi5sb2NhbApjaG93biAiJHtVU0VSQU5ER1JPVVB9IiAiJHtVU0VSX0hPTUV9Ii8udG11eC5jb25mLmxvY2FsLmJhawo="
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
