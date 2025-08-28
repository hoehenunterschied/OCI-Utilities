#!/usr/bin/env bash

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

export OCI_CLI_AUTH="instance_principal"

# download scripts from object storage
BUCKET_NAME="InstanceScripts"
NAMESPACE=$(oci os ns get --query "data" | tr -d '"')
oci os object get -bn "${BUCKET_NAME}" \
                  -ns "${NAMESPACE}" \
                  --file /tmp/setup.bash \
                  --name setup.bash \
    && chmod 755 /tmp/setup.bash

oci os object get -bn "${BUCKET_NAME}" \
                  -ns "${NAMESPACE}" \
                  --file /tmp/boot-init.bash \
                  --name boot-init.bash \
    && chmod 755 /tmp/boot-init.bash

/tmp/boot-init.bash
runuser -u opc /tmp/setup.bash
runuser -u opc
id > /tmp/id.txt
