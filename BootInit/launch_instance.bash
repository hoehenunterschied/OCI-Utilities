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
    "user_data": "IyEvdXNyL2Jpbi9lbnYgYmFzaAoKVVNFUl9IT01FPSIvaG9tZS9vcGMiClVTRVJBTkRHUk9VUD0ib3BjOm9wYyIKVE1VWF9TQ1JJUFQ9InRtdXgtZGVmYXVsdC5iYXNoIgpMRVNTX1NDUklQVD0ib3NtaC1sb2dzLmJhc2giCk9DSV9DT05ORUNUSVZJVFlfU0NSSVBUPSJvY2ktY29ubmVjdGl2aXR5LmJhc2giCgojIGRldGVybWluZSBvcGVyYXRpbmcgc3lzdGVtIHZlcnNpb24KaWYgWyAtZiAvZXRjL29yYWNsZS1yZWxlYXNlIF07IHRoZW4KICAgIHJlbGVhc2VfaW5mbz0kKGNhdCAvZXRjL29yYWNsZS1yZWxlYXNlKQplbGlmIFsgLWYgL2V0Yy9vcy1yZWxlYXNlIF07IHRoZW4KICAgIHJlbGVhc2VfaW5mbz0kKGdyZXAgJ15WRVJTSU9OX0lEPScgL2V0Yy9vcy1yZWxlYXNlIHwgY3V0IC1kPSAtZjIgfCB0ciAtZCAnIicpCmVsc2UKICAgIGVjaG8gIkNhbm5vdCBkZXRlcm1pbmUgT3JhY2xlIExpbnV4IHZlcnNpb24iCmZpCgppZiBbWyAiJHJlbGVhc2VfaW5mbyIgPT0gKiI3LiIqIHx8ICIkcmVsZWFzZV9pbmZvIiA9PSAiNyIgXV07IHRoZW4KICAgIEZJWFBBVEhJTj0iLmJhc2hfcHJvZmlsZSIKICAgIGNhdCA+IC9ldGMveXVtLnJlcG9zLmQvZXBlbC15dW0tb2w3LnJlcG8gPDwgRU9GCltvbDdfZXBlbF0KbmFtZT1PcmFjbGUgTGludXggXCRyZWxlYXNldmVyIEVQRUwgKFwkYmFzZWFyY2gpCmJhc2V1cmw9aHR0cDovL3l1bS5vcmFjbGUuY29tL3JlcG8vT3JhY2xlTGludXgvT0w3L2RldmVsb3Blcl9FUEVML1wkYmFzZWFyY2gvCmdwZ2tleT1maWxlOi8vL2V0Yy9wa2kvcnBtLWdwZy9SUE0tR1BHLUtFWS1vcmFjbGUKZ3BnY2hlY2s9MQplbmFibGVkPTEKRU9GCiAgICB5dW0gaW5zdGFsbCAteSBnaXQgaHRvcCBiaXNvbiBhdXRvbWFrZSBnY2Mga2VybmVsLWRldmVsIG1ha2UgbmN1cnNlcy1kZXZlbCBsaWJldmVudC1kZXZlbAogICAgcHVzaGQgL3RtcCAmJiBnaXQgY2xvbmUgaHR0cHM6Ly9naXRodWIuY29tL3RtdXgvdG11eC5naXQgXAogICAgICAmJiBjZCB0bXV4IFwKICAgICAgJiYgc2ggYXV0b2dlbi5zaCBcCiAgICAgICYmIC4vY29uZmlndXJlICYmIG1ha2UgJiYgbWFrZSBpbnN0YWxsCiAgICBwb3BkCmVsaWYgW1sgIiRyZWxlYXNlX2luZm8iID09ICoiOC4iKiB8fCAiJHJlbGVhc2VfaW5mbyIgPT0gIjgiIF1dOyB0aGVuCiAgICBGSVhQQVRISU49Ii5iYXNocmMiCiAgICBkbmYgLXkgY29uZmlnLW1hbmFnZXIgLS1lbmFibGUgb2w4X2RldmVsb3Blcl9FUEVMCiAgICBkbmYgLXkgaW5zdGFsbCB0bXV4IGdpdCBodG9wCmVsaWYgW1sgIiRyZWxlYXNlX2luZm8iID09ICoiOS4iKiB8fCAiJHJlbGVhc2VfaW5mbyIgPT0gIjkiIF1dOyB0aGVuCiAgICBGSVhQQVRISU49Ii5iYXNocmMiCiAgICBkbmYgLXkgY29uZmlnLW1hbmFnZXIgLS1lbmFibGUgb2w5X2RldmVsb3Blcl9FUEVMCiAgICBkbmYgLXkgaW5zdGFsbCB0bXV4IGdpdCBodG9wCmVsc2UKICAgIGVjaG8gIlVua25vd24gb3IgdW5zdXBwb3J0ZWQgT3JhY2xlIExpbnV4IHZlcnNpb246ICRyZWxlYXNlX2luZm8iCmZpCgoKc2VkIC0taW4tcGxhY2U9LmJhayAtZSAncy9cJEhPTUVcL2Jpbi8kSE9NRVwvLmJpbi8nICIke1VTRVJfSE9NRX0iLyIke0ZJWFBBVEhJTn0iCm1rZGlyICIke1VTRVJfSE9NRX0vLmJpbiIgJiYgY2hvd24gIiR7VVNFUkFOREdST1VQfSIgIiR7VVNFUl9IT01FfSIvLmJpbgoKY2F0ID4gIiR7VVNFUl9IT01FfS8uYmluLyR7VE1VWF9TQ1JJUFR9IiA8PCBFT0YKIyEvdXNyL2Jpbi9lbnYgYmFzaAppZiBbICEgLWQgIlwke0hPTUV9L3RtcCIgXTsgdGhlbgogIG1rZGlyICJcJHtIT01FfS90bXAiCmZpCmNkICJcJHtIT01FfS90bXAiCnRtdXggaGFzLXNlc3Npb24gLXQgIlwkKGhvc3RuYW1lKSIgJiYgdG11eCBhdHRhY2gtc2Vzc2lvbiAtdCAiXCQoaG9zdG5hbWUpIiB8fCB0bXV4IG5ldy1zZXNzaW9uIC1zICJcJChob3N0bmFtZSkiXDsgXFwKICAgICBzcGxpdC13aW5kb3cgLWggXDsgXFwKICAgICBzZW5kLWtleXMgJ2h0b3AnIEMtbVw7IFxcCiAgICAgc3BsaXQtd2luZG93IC12XDsgXFwKICAgICBzZWxlY3QtcGFuZSAtdCAxXDsKRU9GCmNobW9kIHVnK3ggIiR7VVNFUl9IT01FfSIvLmJpbi8iJHtUTVVYX1NDUklQVH0iCmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy5iaW4vIiR7VE1VWF9TQ1JJUFR9IgoKY2F0ID4+ICIke1VTRVJfSE9NRX0iLy5iYXNoX3Byb2ZpbGUgPDwgRU9GCmlmIFtbIC16IFwkVE1VWCBdXSAmJiBbWyAtbiBcJFNTSF9UVFkgXV07IHRoZW4KCSAgIlwke0hPTUV9Ii8uYmluLyIke1RNVVhfU0NSSVBUfSIKZmkKRU9GCgpjYXQgPiAiJHtVU0VSX0hPTUV9Ly5iaW4vJHtMRVNTX1NDUklQVH0iIDw8IEVPRgojIS91c3IvYmluL2VudiBiYXNoCgojIGZpbGVuYW1lIG9mIHRoaXMgc2NyaXB0ClRISVNfU0NSSVBUPSJcJChiYXNlbmFtZSBcJHtCQVNIX1NPVVJDRX0pIgojIHJlc3RhcnQgc2NyaXB0IGFzIHN1ZG8gaWYgZWZmZWN0aXZlIHVzZXIgaWQgaXMgbm90IHJvb3QKaWYgW1sgIlwkRVVJRCIgLW5lIDAgXV07IHRoZW4KICAgIGV4ZWMgc3VkbyAiXCR7QkFTSF9TT1VSQ0V9IiAiXCRAIgpmaQoKTE9HPSgpCkxPRys9KCcvdmFyL2xpYi9vcmFjbGUtY2xvdWQtYWdlbnQvcGx1Z2lucy9vY2ktb3NtaC9vc21oLWFnZW50L3N0YXRlRGlyL2xvZy9vc21oLWFnZW50LmxvZycpCkxPRys9KCcvdmFyL2xvZy9vcmFjbGUtY2xvdWQtYWdlbnQvcGx1Z2lucy9vY2ktb3NtaC9vY2ktb3NtaC5sb2cnKQpMT0crPSgnL3Zhci9sb2cvb3JhY2xlLWNsb3VkLWFnZW50L2FnZW50LmxvZycpCgojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KIyBDb2xvcnMKIyAtLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tCk5PQ09MT1I9J1xceDFCWzBtJwpSRUQ9J1xceDFCWzA7MzFtJwpHUkVFTj0nXFx4MUJbMDszMm0nCk9SQU5HRT0nXFx4MUJbMDszM20nCkJMVUU9J1xceDFCWzA7MzRtJwpQVVJQTEU9J1xceDFCWzA7MzVtJwpDWUFOPSdcXHgxQlswOzM2bScKTElHSFRHUkFZPSdcXHgxQlswOzM3bScKREFSS0dSQVk9J1xceDFCWzE7MzBtJwpMSUdIVFJFRD0nXFx4MUJbMTszMW0nCkxJR0hUR1JFRU49J1xceDFCWzE7MzJtJwpZRUxMT1c9J1xceDFCWzE7MzNtJwpMSUdIVEJMVUU9J1xceDFCWzE7MzRtJwpMSUdIVFBVUlBMRT0nXFx4MUJbMTszNW0nCkxJR0hUQ1lBTj0nXFx4MUJbMTszNm0nCldISVRFPSdcXHgxQlsxOzM3bScKCldBVENITElTVD0oKQpmb3IgbG9nIGluICJcJHtMT0dbQF19IjsgZG8KICBpZiBbWyAtcyAiXCR7bG9nfSIgXV07IHRoZW4KICAgIGVjaG8gLWUgIlwke0dSRUVOfVwke2xvZ31cJHtOT0NPTE9SfSIKICAgIFdBVENITElTVCs9KCJcJHtsb2d9IikKICBlbHNlCiAgICBlY2hvIC1lICJcJHtSRUR9XCR7bG9nfVwke05PQ09MT1J9IgogIGZpCmRvbmUKaWYgWyBcJHsjV0FUQ0hMSVNUW0BdfSAtZXEgMCBdOyB0aGVuCiAgZXhpdApmaQpmb3IgbG9nIGluICJcJHtXQVRDSExJU1RbQF19IjsgZG8KICBzdWRvIGxlc3MgIlwke2xvZ30iCmRvbmUKRU9GCmNobW9kIHVnK3ggIiR7VVNFUl9IT01FfSIvLmJpbi8iJHtMRVNTX1NDUklQVH0iCmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy5iaW4vIiR7TEVTU19TQ1JJUFR9IgoKY2F0ID4gIiR7VVNFUl9IT01FfS8uYmluLyR7T0NJX0NPTk5FQ1RJVklUWV9TQ1JJUFR9IiA8PCBFT0YKIyEvdXNyL2Jpbi9lbnYgYmFzaAoKdGVtcGZpbGU9XCQobWt0ZW1wKQplY2hvICJUZW1wb3JhcnkgZmlsZSBjcmVhdGVkOiBcJHRlbXBmaWxlIgoKY3VybCAtcyAtSCAiQXV0aG9yaXphdGlvbjogQmVhcmVyIE9yYWNsZSIgaHR0cDovLzE2OS4yNTQuMTY5LjI1NC9vcGMvdjIvaW5zdGFuY2UvcmVnaW9uSW5mbyA+ICJcJHt0ZW1wZmlsZX0iCmV4cG9ydCBSRUdJT049XCQoY2F0ICJcJHt0ZW1wZmlsZX0iIHwganEgLXIgIi5yZWdpb25JZGVudGlmaWVyIikKZXhwb3J0IERPTUFJTj1cJChjYXQgIlwke3RlbXBmaWxlfSIgfCBqcSAtciAiLnJlYWxtRG9tYWluQ29tcG9uZW50IikKY3VybCAtcyBodHRwczovL29zbWguIlwke1JFR0lPTn0iLm9jaS4iXCR7RE9NQUlOfSIgJj4vZGV2L251bGwgOyBbIFwkPyA9PSAwIF0gJiYgZWNobyAiU3VjY2VzcyIgfHwgZWNobyAiRmFpbHVyZSIKcm0gIlwke3RlbXBmaWxlfSIKRU9GCmNobW9kIHVnK3ggIiR7VVNFUl9IT01FfSIvLmJpbi8iJHtPQ0lfQ09OTkVDVElWSVRZX1NDUklQVH0iCmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy5iaW4vIiR7T0NJX0NPTk5FQ1RJVklUWV9TQ1JJUFR9IgoKY2QgIiR7VVNFUl9IT01FfSIKZ2l0IGNsb25lIC0tc2luZ2xlLWJyYW5jaCBodHRwczovL2dpdGh1Yi5jb20vZ3Bha29zei8udG11eC5naXQKbG4gLXMgLWYgLnRtdXgvLnRtdXguY29uZgpjcCAudG11eC8udG11eC5jb25mLmxvY2FsIC4Kc2VkIC0taW4tcGxhY2U9LmJhayAtZSAncy9eI3NldCAtZyBtb3VzZSBvbi9zZXQgLWcgbW91c2Ugb24vJyAiJHtVU0VSX0hPTUV9Ii8udG11eC5jb25mLmxvY2FsCmNob3duIC1SICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy50bXV4CmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy50bXV4LmNvbmYKY2hvd24gIiR7VVNFUkFOREdST1VQfSIgIiR7VVNFUl9IT01FfSIvLnRtdXguY29uZi5sb2NhbApjaG93biAiJHtVU0VSQU5ER1JPVVB9IiAiJHtVU0VSX0hPTUV9Ii8udG11eC5jb25mLmxvY2FsLmJhawo="
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
