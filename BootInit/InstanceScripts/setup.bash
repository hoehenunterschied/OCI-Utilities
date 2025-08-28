#!/usr/bin/env bash

DNSHOSTNAME="rpiconnect"
DNSDOMAIN="katogana.de"
NSGS=()
NSGS+=('EternalTerminal')
VCN="MainNet"

# if we are not in an OCI instance, quit
curl --connect-timeout 5 -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/id || exit
echo ""
INSTANCE_NAME="$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/displayName)"

source /etc/os-release
if [[ "$NAME" == "Oracle Linux Server" ]]; then
  if [[ "$VERSION_ID" == 8* ]]; then
    echo "Oracle Linux 8"
    sudo dnf install oraclelinux-developer-release-el8
    sudo dnf install oracle-epel-release-el8
    sudo dnf -y install python36-oci-cli
  elif [[ "$VERSION_ID" == 9* ]]; then
    echo "Oracle Linux 9"
    sudo dnf install oraclelinux-developer-release-el9
    sudo dnf install oracle-epel-release-el9
    sudo dnf -y install python39-oci-cli
  else
    echo "### version not supported: $VERSION_ID"
    exit
  fi
else
  echo "OS not supported: $NAME"
  exit
fi

sudo dnf -y install et
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  NSGS+=('HTTP')
  sudo dnf -y install httpd
  sudo systemctl --now enable httpd
  sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
fi
sudo systemctl --now enable et
sudo firewall-cmd --permanent --zone=public --add-port=2022/tcp
sudo firewall-cmd --reload

cat >> ~/.bash_profile << EOF
export OCI_CLI_AUTH="instance_principal"
EOF

export OCI_CLI_AUTH="instance_principal"
INSTANCE_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/id)

# download scripts from object storage
BUCKET_NAME="InstanceScripts"
NAMESPACE=$(oci os ns get --query "data" | tr -d '"')

if [ ! -d "${HOME}/.oci" ]; then
  mkdir "${HOME}/.oci"
fi
if [ ! -d "${HOME}/.bin" ]; then
  mkdir "${HOME}/.bin"
fi

FILE=();                    LOCATION=();          PERMS=();
FILE+=('instancectl.bash'); LOCATION+=("$HOME/.bin"); PERMS+=('755');
FILE+=('params.txt');       LOCATION+=("$HOME/.bin"); PERMS+=('600');
FILE+=('oci_cli_rc');       LOCATION+=("$HOME/.oci"); PERMS+=('600');
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  FILE+=('rpi-connect.bash'); LOCATION+=("$HOME/.bin"); PERMS+=('755');
else
  FILE+=('register-to-osmh.bash'); LOCATION+=("$HOME/.bin"); PERMS+=('755');
fi

for i in "${!FILE[@]}"; do
  printf "\n%-22s %15s %3s\n" "${FILE[$i]}" "${LOCATION[$i]}" "${PERMS[$i]}"
  oci os object get -bn "${BUCKET_NAME}" \
                    -ns "${NAMESPACE}" \
                    --file "${LOCATION[$i]}/${FILE[$i]}" \
                    --name "${FILE[$i]}" \
    && chmod "${PERMS[$i]}" "${LOCATION[$i]}/${FILE[$i]}"
done

# VCN
VCN_ID=$(oci network vcn list --all --query "data[?\"display-name\"=='MainNet']|[0].id" | tr -d '"')
# VNIC
VNIC_ID=$(oci compute instance list-vnics --instance-id "${INSTANCE_ID}" --query "data[].id|[0]" | tr -d '"')
# NSG
NSG_LIST="[ \""
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  for f in $(oci network nsg list --all --query "data[?(\"display-name\"=='EternalTerminal' || \"display-name\" == 'HTTP') && \"vcn-id\" == '$VCN_ID'].id" | jq -c ".[]" | tr -d '"'); do
    NSG_LIST="${NSG_LIST}$f\", \""
  done
else
  for f in $(oci network nsg list --all --query "data[?(\"display-name\"=='EternalTerminal') && \"vcn-id\" == '$VCN_ID'].id" | jq -c ".[]" | tr -d '"'); do
    NSG_LIST="${NSG_LIST}$f\", \""
  done
fi
NSG_LIST="${NSG_LIST%, \"}]"


# set the NSGs and retrieve the public ip address
PUBLIC_IP="$(oci network vnic update --force --vnic-id "$VNIC_ID" --nsg-ids "$NSG_LIST" --query "data.\"public-ip\"" | tr -d '"')"

if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  # set defined tag ResourceControl.keep = true
  oci compute instance update --force --instance-id "${INSTANCE_ID}" --defined-tags "$(oci-metadata --json --value-only --get definedTags | sed "s/'/\"/g" | jq '.ResourceControl.keepup = "true"')"

  # create DNS entry
  ZONE_ID=$(oci dns zone list \
                --raw-output \
                --query "data[?name=='${DNSDOMAIN}'] | [0].id")
  echo "### zone_id: ${ZONE_ID}"

  oci dns record rrset update \
      --force \
      --domain "${DNSHOSTNAME}.${DNSDOMAIN}" \
      --rtype "A" \
      --zone-name-or-id ${ZONE_ID} \
      --items "[{\"domain\":\"${DNSHOSTNAME}.${DNSDOMAIN}\",\"rdata\":\"${PUBLIC_IP}\" ,\"rtype\":\"A\",\"ttl\":30}]"
fi
