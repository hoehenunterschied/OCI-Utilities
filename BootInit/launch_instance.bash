#!/usr/bin/env bash

NAME=();                 OS=();                       CPU=();
NAME+=('ol9arm1');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
NAME+=('ol9arm2');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
NAME+=('ol9arm3');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
NAME+=('ol9arm4');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
NAME+=('ol9arm5');        OS+=('Oracle Linux 9');      CPU+=('Ampere');
NAME+=('ol8arm1');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
NAME+=('ol8arm2');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
NAME+=('ol8arm3');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
NAME+=('ol8arm4');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
NAME+=('ol8arm5');        OS+=('Oracle Linux 8');      CPU+=('Ampere');
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
    "user_data": "IyEvdXNyL2Jpbi9lbnYgYmFzaAoKVVNFUl9IT01FPSIvaG9tZS9vcGMiClVTRVJBTkRHUk9VUD0ib3BjOm9wYyIKVE1VWF9TQ1JJUFQ9InRtdXgtZGVmYXVsdC5iYXNoIgpMRVNTX1NDUklQVD0ib3NtaC1sb2dzLmJhc2giCk9DSV9DT05ORUNUSVZJVFlfU0NSSVBUPSJvY2ktY29ubmVjdGl2aXR5LmJhc2giCgojIGRldGVybWluZSBvcGVyYXRpbmcgc3lzdGVtIHZlcnNpb24KaWYgWyAtZiAvZXRjL29yYWNsZS1yZWxlYXNlIF07IHRoZW4KICAgIHJlbGVhc2VfaW5mbz0kKGNhdCAvZXRjL29yYWNsZS1yZWxlYXNlKQplbGlmIFsgLWYgL2V0Yy9vcy1yZWxlYXNlIF07IHRoZW4KICAgIHJlbGVhc2VfaW5mbz0kKGdyZXAgJ15WRVJTSU9OX0lEPScgL2V0Yy9vcy1yZWxlYXNlIHwgY3V0IC1kPSAtZjIgfCB0ciAtZCAnIicpCmVsc2UKICAgIGVjaG8gIkNhbm5vdCBkZXRlcm1pbmUgT3JhY2xlIExpbnV4IHZlcnNpb24iCmZpCgppZiBbWyAiJHJlbGVhc2VfaW5mbyIgPT0gKiI3LiIqIHx8ICIkcmVsZWFzZV9pbmZvIiA9PSAiNyIgXV07IHRoZW4KICAgIEZJWFBBVEhJTj0iLmJhc2hfcHJvZmlsZSIKICAgIGNhdCA+IC9ldGMveXVtLnJlcG9zLmQvZXBlbC15dW0tb2w3LnJlcG8gPDwgRU9GCltvbDdfZXBlbF0KbmFtZT1PcmFjbGUgTGludXggXCRyZWxlYXNldmVyIEVQRUwgKFwkYmFzZWFyY2gpCmJhc2V1cmw9aHR0cDovL3l1bS5vcmFjbGUuY29tL3JlcG8vT3JhY2xlTGludXgvT0w3L2RldmVsb3Blcl9FUEVML1wkYmFzZWFyY2gvCmdwZ2tleT1maWxlOi8vL2V0Yy9wa2kvcnBtLWdwZy9SUE0tR1BHLUtFWS1vcmFjbGUKZ3BnY2hlY2s9MQplbmFibGVkPTEKRU9GCiAgICB5dW0gaW5zdGFsbCAteSBnaXQgaHRvcCBiaXNvbiBhdXRvbWFrZSBnY2Mga2VybmVsLWRldmVsIG1ha2UgbmN1cnNlcy1kZXZlbCBsaWJldmVudC1kZXZlbAogICAgcHVzaGQgL3RtcCAmJiBnaXQgY2xvbmUgaHR0cHM6Ly9naXRodWIuY29tL3RtdXgvdG11eC5naXQgXAogICAgICAmJiBjZCB0bXV4IFwKICAgICAgJiYgc2ggYXV0b2dlbi5zaCBcCiAgICAgICYmIC4vY29uZmlndXJlICYmIG1ha2UgJiYgbWFrZSBpbnN0YWxsCiAgICBwb3BkCmVsaWYgW1sgIiRyZWxlYXNlX2luZm8iID09ICoiOC4iKiB8fCAiJHJlbGVhc2VfaW5mbyIgPT0gIjgiIF1dOyB0aGVuCiAgICBGSVhQQVRISU49Ii5iYXNocmMiCiAgICBkbmYgLXkgY29uZmlnLW1hbmFnZXIgLS1lbmFibGUgb2w4X2RldmVsb3Blcl9FUEVMCiAgICBkbmYgLXkgaW5zdGFsbCB0bXV4IGdpdCBodG9wCmVsaWYgW1sgIiRyZWxlYXNlX2luZm8iID09ICoiOS4iKiB8fCAiJHJlbGVhc2VfaW5mbyIgPT0gIjkiIF1dOyB0aGVuCiAgICBGSVhQQVRISU49Ii5iYXNocmMiCiAgICBkbmYgLXkgY29uZmlnLW1hbmFnZXIgLS1lbmFibGUgb2w5X2RldmVsb3Blcl9FUEVMCiAgICBkbmYgLXkgaW5zdGFsbCB0bXV4IGdpdCBodG9wCmVsc2UKICAgIGVjaG8gIlVua25vd24gb3IgdW5zdXBwb3J0ZWQgT3JhY2xlIExpbnV4IHZlcnNpb246ICRyZWxlYXNlX2luZm8iCmZpCgoKc2VkIC0taW4tcGxhY2U9LmJhayAtZSAncy9cJEhPTUVcL2Jpbi8kSE9NRVwvLmJpbi8nICIke1VTRVJfSE9NRX0iLyIke0ZJWFBBVEhJTn0iCm1rZGlyICIke1VTRVJfSE9NRX0vLmJpbiIgJiYgY2hvd24gIiR7VVNFUkFOREdST1VQfSIgIiR7VVNFUl9IT01FfSIvLmJpbgoKY2F0ID4gIiR7VVNFUl9IT01FfS8uYmluLyR7VE1VWF9TQ1JJUFR9IiA8PCBFT0YKIyEvdXNyL2Jpbi9lbnYgYmFzaAppZiBbICEgLWQgIlwke0hPTUV9L3RtcCIgXTsgdGhlbgogIG1rZGlyICJcJHtIT01FfS90bXAiCmZpCmNkICJcJHtIT01FfS90bXAiCnRtdXggaGFzLXNlc3Npb24gLXQgIlwkKGhvc3RuYW1lKSIgJiYgdG11eCBhdHRhY2gtc2Vzc2lvbiAtdCAiXCQoaG9zdG5hbWUpIiB8fCB0bXV4IG5ldy1zZXNzaW9uIC1zICJcJChob3N0bmFtZSkiXDsgXFwKICAgICBzcGxpdC13aW5kb3cgLWggXDsgXFwKICAgICBzZW5kLWtleXMgJ2h0b3AnIEMtbVw7IFxcCiAgICAgc3BsaXQtd2luZG93IC12XDsgXFwKICAgICBzZWxlY3QtcGFuZSAtdCAxXDsKRU9GCmNobW9kIHVnK3ggIiR7VVNFUl9IT01FfSIvLmJpbi8iJHtUTVVYX1NDUklQVH0iCmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy5iaW4vIiR7VE1VWF9TQ1JJUFR9IgoKY2F0ID4+ICIke1VTRVJfSE9NRX0iLy5iYXNoX3Byb2ZpbGUgPDwgRU9GCmlmIFtbIC16IFwkVE1VWCBdXSAmJiBbWyAtbiBcJFNTSF9UVFkgXV07IHRoZW4KCSAgIlwke0hPTUV9Ii8uYmluLyIke1RNVVhfU0NSSVBUfSIKZmkKRU9GCgpjYXQgPiAiJHtVU0VSX0hPTUV9Ly5iaW4vJHtMRVNTX1NDUklQVH0iIDw8IEVPRgojIS91c3IvYmluL2VudiBiYXNoCgpMT0c9KCkKTE9HKz0oJy92YXIvbGliL29yYWNsZS1jbG91ZC1hZ2VudC9wbHVnaW5zL29jaS1vc21oL29zbWgtYWdlbnQvc3RhdGVEaXIvbG9nL29zbWgtYWdlbnQubG9nJykKTE9HKz0oJy92YXIvbG9nL29yYWNsZS1jbG91ZC1hZ2VudC9wbHVnaW5zL29jaS1vc21oL29jaS1vc21oLmxvZycpCkxPRys9KCcvdmFyL2xvZy9vcmFjbGUtY2xvdWQtYWdlbnQvYWdlbnQubG9nJykKCiMgLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIENvbG9ycwojIC0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0KTk9DT0xPUj0nXFx4MUJbMG0nClJFRD0nXFx4MUJbMDszMW0nCkdSRUVOPSdcXHgxQlswOzMybScKT1JBTkdFPSdcXHgxQlswOzMzbScKQkxVRT0nXFx4MUJbMDszNG0nClBVUlBMRT0nXFx4MUJbMDszNW0nCkNZQU49J1xceDFCWzA7MzZtJwpMSUdIVEdSQVk9J1xceDFCWzA7MzdtJwpEQVJLR1JBWT0nXFx4MUJbMTszMG0nCkxJR0hUUkVEPSdcXHgxQlsxOzMxbScKTElHSFRHUkVFTj0nXFx4MUJbMTszMm0nCllFTExPVz0nXFx4MUJbMTszM20nCkxJR0hUQkxVRT0nXFx4MUJbMTszNG0nCkxJR0hUUFVSUExFPSdcXHgxQlsxOzM1bScKTElHSFRDWUFOPSdcXHgxQlsxOzM2bScKV0hJVEU9J1xceDFCWzE7MzdtJwoKV0FUQ0hMSVNUPSgpCmZvciBsb2cgaW4gIlwke0xPR1tAXX0iOyBkbwogIGlmIFtbIC1zICJcJHtsb2d9IiBdXTsgdGhlbgogICAgZWNobyAtZSAiXCR7R1JFRU59XCR7bG9nfVwke05PQ09MT1J9IgogICAgV0FUQ0hMSVNUKz0oIlwke2xvZ30iKQogIGVsc2UKICAgIGVjaG8gLWUgIlwke1JFRH1cJHtsb2d9XCR7Tk9DT0xPUn0iCiAgZmkKZG9uZQppZiBbIFwkeyNXQVRDSExJU1RbQF19IC1lcSAwIF07IHRoZW4KICBleGl0CmZpCmZvciBsb2cgaW4gIlwke1dBVENITElTVFtAXX0iOyBkbwogIHN1ZG8gbGVzcyAiXCR7bG9nfSIKZG9uZQpFT0YKY2htb2QgdWcreCAiJHtVU0VSX0hPTUV9Ii8uYmluLyIke0xFU1NfU0NSSVBUfSIKY2hvd24gIiR7VVNFUkFOREdST1VQfSIgIiR7VVNFUl9IT01FfSIvLmJpbi8iJHtMRVNTX1NDUklQVH0iCgpjYXQgPiAiJHtVU0VSX0hPTUV9Ly5iaW4vJHtPQ0lfQ09OTkVDVElWSVRZX1NDUklQVH0iIDw8IEVPRgojIS91c3IvYmluL2VudiBiYXNoCgp0ZW1wZmlsZT1cJChta3RlbXApCmVjaG8gIlRlbXBvcmFyeSBmaWxlIGNyZWF0ZWQ6IFwkdGVtcGZpbGUiCgpjdXJsIC1zIC1IICJBdXRob3JpemF0aW9uOiBCZWFyZXIgT3JhY2xlIiBodHRwOi8vMTY5LjI1NC4xNjkuMjU0L29wYy92Mi9pbnN0YW5jZS9yZWdpb25JbmZvID4gIlwke3RlbXBmaWxlfSIKZXhwb3J0IFJFR0lPTj1cJChjYXQgIlwke3RlbXBmaWxlfSIgfCBqcSAtciAiLnJlZ2lvbklkZW50aWZpZXIiKQpleHBvcnQgRE9NQUlOPVwkKGNhdCAiXCR7dGVtcGZpbGV9IiB8IGpxIC1yICIucmVhbG1Eb21haW5Db21wb25lbnQiKQpjdXJsIC1zIGh0dHBzOi8vb3NtaC4iXCR7UkVHSU9OfSIub2NpLiJcJHtET01BSU59IiAmPi9kZXYvbnVsbCA7IFsgXCQ/ID09IDAgXSAmJiBlY2hvICJTdWNjZXNzIiB8fCBlY2hvICJGYWlsdXJlIgpybSAiXCR7dGVtcGZpbGV9IgpFT0YKY2htb2QgdWcreCAiJHtVU0VSX0hPTUV9Ii8uYmluLyIke09DSV9DT05ORUNUSVZJVFlfU0NSSVBUfSIKY2hvd24gIiR7VVNFUkFOREdST1VQfSIgIiR7VVNFUl9IT01FfSIvLmJpbi8iJHtPQ0lfQ09OTkVDVElWSVRZX1NDUklQVH0iCgpjZCAiJHtVU0VSX0hPTUV9IgpnaXQgY2xvbmUgLS1zaW5nbGUtYnJhbmNoIGh0dHBzOi8vZ2l0aHViLmNvbS9ncGFrb3N6Ly50bXV4LmdpdApsbiAtcyAtZiAudG11eC8udG11eC5jb25mCmNwIC50bXV4Ly50bXV4LmNvbmYubG9jYWwgLgpzZWQgLS1pbi1wbGFjZT0uYmFrIC1lICdzL14jc2V0IC1nIG1vdXNlIG9uL3NldCAtZyBtb3VzZSBvbi8nICIke1VTRVJfSE9NRX0iLy50bXV4LmNvbmYubG9jYWwKY2hvd24gLVIgIiR7VVNFUkFOREdST1VQfSIgIiR7VVNFUl9IT01FfSIvLnRtdXgKY2hvd24gIiR7VVNFUkFOREdST1VQfSIgIiR7VVNFUl9IT01FfSIvLnRtdXguY29uZgpjaG93biAiJHtVU0VSQU5ER1JPVVB9IiAiJHtVU0VSX0hPTUV9Ii8udG11eC5jb25mLmxvY2FsCmNob3duICIke1VTRVJBTkRHUk9VUH0iICIke1VTRVJfSE9NRX0iLy50bXV4LmNvbmYubG9jYWwuYmFrCg=="
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
