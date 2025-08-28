#!/usr/bin/env bash
# convert this file with
#  cat <filename> | base64 --wrap 0
# and put it as user_data in the launch script
exec > /tmp/boot-init-output.txt 2>&1

source /etc/os-release
if [[ "$NAME" == "Oracle Linux Server" ]]; then
  if [[ "$VERSION_ID" == 8* ]]; then
    echo "Oracle Linux 8"
    dnf install oraclelinux-developer-release-el8
    dnf install oracle-epel-release-el8
    dnf -y config-manager --enable ol8_developer_EPEL
    dnf -y install python36-oci-cli
  elif [[ "$VERSION_ID" == 9* ]]; then
    echo "Oracle Linux 9"
    dnf install oraclelinux-developer-release-el9
    dnf install oracle-epel-release-el9
    dnf -y config-manager --enable ol9_developer_EPEL
    dnf -y install python39-oci-cli
  else
    echo "### version not supported: $VERSION_ID"
    exit
  fi
else
  echo "OS not supported: $NAME"
  exit
fi

# install tmux, git, htop and Eternal Terminal
dnf -y install tmux git htop et
systemctl --now enable et
firewall-cmd --permanent --zone=public --add-port=2022/tcp

INSTANCE_NAME="$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/displayName)"
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  dnf -y install httpd
  systemctl --now enable httpd
  firewall-cmd --permanent --zone=public --add-port=80/tcp
fi
firewall-cmd --reload

export OCI_CLI_AUTH="instance_principal"

# download scripts from object storage
BUCKET_NAME="InstanceScripts"
NAMESPACE=$(oci os ns get --query "data" | tr -d '"')
oci os object get -bn "${BUCKET_NAME}" \
                  -ns "${NAMESPACE}" \
                  --file /tmp/user-setup.bash \
                  --name user-setup.bash \
    && chmod 755 /tmp/user-setup.bash

runuser -u opc /tmp/user-setup.bash
runuser -u opc id > /tmp/id.txt
