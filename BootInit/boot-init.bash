#!/usr/bin/env bash
# convert this file with
#  cat <filename> | base64 --wrap 0
# and put it as user_data in the launch script
exec > /tmp/boot-init-output.txt 2>&1

source /etc/os-release
if [[ "$NAME" == "Oracle Linux Server" ]]; then
  if [[ "$VERSION_ID" == 8* ]]; then
    echo "Oracle Linux 8"
    dnf -y install python36-oci-cli
  elif [[ "$VERSION_ID" == 9* ]]; then
    echo "Oracle Linux 9"
    dnf -y install python39-oci-cli
  elif [[ "$VERSION_ID" == 10* ]]; then
    echo "Oracle Linux 10"
    dnf -y install python3-oci-cli
  else
    echo "### version not supported: $VERSION_ID"
    exit
  fi
else
  echo "OS not supported: $NAME"
  exit
fi

export OCI_CLI_AUTH="instance_principal"

# download scripts from object storage
BUCKET_NAME="InstanceScripts"
NAMESPACE=$(oci os ns get --query "data" | tr -d '"')
oci os object get -bn "${BUCKET_NAME}" \
                  -ns "${NAMESPACE}" \
                  --file /tmp/root-setup.bash \
                  --name root-setup.bash \
    && chmod 755 /tmp/root-setup.bash

oci os object get -bn "${BUCKET_NAME}" \
                  -ns "${NAMESPACE}" \
                  --file /tmp/user-setup.bash \
                  --name user-setup.bash \
    && chmod 755 /tmp/user-setup.bash

/tmp/root-setup.bash
runuser -u opc /tmp/user-setup.bash
runuser -u opc id > /tmp/id.txt
