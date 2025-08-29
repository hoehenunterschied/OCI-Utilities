#!/usr/bin/env bash

# redirect all output to a file
exec > /tmp/user-setup-output.txt 2>&1

DNSHOSTNAME="rpiconnect"
DNSDOMAIN="katogana.de"
NSGS=()
NSGS+=('EternalTerminal')
VCN="MainNet"
TMUX_SCRIPT="tmux-default.bash"

# if we are not in an OCI instance, quit
curl --connect-timeout 5 -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/id || exit
echo ""
INSTANCE_NAME="$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/displayName)"

# use ~/.bin instead of ~/bin
sed --in-place=.bak -e 's/\$HOME\/bin/$HOME\/.bin/' "${HOME}"/.bashrc

# use tmux on interactive shells
cat >> "${HOME}"/.bash_profile << EOF
if [[ -z \$TMUX ]] && [[ -n \$SSH_TTY ]]; then
	  "\${HOME}/.bin/${TMUX_SCRIPT}"
fi
EOF

# install Oh my Tmux!
cd
git clone --single-branch https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
sed --in-place=.bak -e 's/^#set -g mouse on/set -g mouse on/' "${HOME}"/.tmux.conf.local

# prepare for using OCI CLI with instance principal authorization
cat >> ~/.bash_profile << EOF
export OCI_CLI_AUTH="instance_principal"
EOF
# either source ~/.bash_profile or set OCI_CLI_AUTH
export OCI_CLI_AUTH="instance_principal"

INSTANCE_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/id)

#
# download scripts from object storage
#
# make sure the target directories for the downloaded files exist
if [ ! -d "${HOME}/.oci" ]; then
  mkdir "${HOME}/.oci"
fi
if [ ! -d "${HOME}/.bin" ]; then
  mkdir "${HOME}/.bin"
fi

# setup the file list
FILE=();                         LOCATION=();              PERMS=();
FILE+=('instancectl.bash');      LOCATION+=("$HOME/.bin"); PERMS+=('755');
FILE+=('oci_cli_rc');            LOCATION+=("$HOME/.oci"); PERMS+=('600');
FILE+=('oci-connectivity.bash'); LOCATION+=("$HOME/.bin"); PERMS+=('755');
FILE+=('osmh-logs.bash');        LOCATION+=("$HOME/.bin"); PERMS+=('755');
FILE+=('params.txt');            LOCATION+=("$HOME/.bin"); PERMS+=('600');
FILE+=('tmux-default.bash');     LOCATION+=("$HOME/.bin"); PERMS+=('755');
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  FILE+=('rpi-connect.bash'); LOCATION+=("$HOME/.bin"); PERMS+=('755');
else
  FILE+=('register-to-osmh.bash'); LOCATION+=("$HOME/.bin"); PERMS+=('755');
fi

BUCKET_NAME="InstanceScripts"
NAMESPACE=$(oci os ns get --query "data" | tr -d '"')
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
  oci compute instance update --force --instance-id "${INSTANCE_ID}" --defined-tags "$(oci-metadata --json --value-only --get definedTags | sed "s/'/\"/g" | jq '.ResourceControl.keepup = "true" | .ResourceControl.instancectl = "false"')"

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

echo "### it seems to be a problem (at least in Oracle Linux 8)"
echo "### to execute firewall-cmd from within boot-init."
echo "### Trying to do this via at job"
echo "### ATJOB_FILE="/tmp/atjob.bash""
ATJOB_FILE="/tmp/atjob.bash"
echo "### cat > \"\${ATJOB_FILE}\" << EOF"
cat > "${ATJOB_FILE}" << EOF
#!/usr/bin/env bash

EOF
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  echo "### echo \"sudo firewall-cmd --permanent --zone=public --add-port=80/tcp\" >> \"\${ATJOB_FILE}\""
  echo "sudo firewall-cmd --permanent --zone=public --add-port=80/tcp" >> "${ATJOB_FILE}"
fi
echo "### echo \"sudo firewall-cmd --permanent --zone=public --add-port=2022/tcp\" >> \"\${ATJOB_FILE}\""
echo "sudo firewall-cmd --permanent --zone=public --add-port=2022/tcp" >> "${ATJOB_FILE}"
echo "### echo \"sudo firewall-cmd --reload\" >> \"\${ATJOB_FILE}\""
echo "sudo firewall-cmd --reload" >> "${ATJOB_FILE}"
echo "### chmod +x "${ATJOB_FILE}""
chmod +x "${ATJOB_FILE}"
echo "### user-setup script finished"
