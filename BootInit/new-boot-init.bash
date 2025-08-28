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
                  --file /tmp/root-stage.bash \
                  --name root-stage.bash \
    && chmod 755 /tmp/root-stage.bash

oci os object get -bn "${BUCKET_NAME}" \
                  -ns "${NAMESPACE}" \
                  --file /tmp/user-stage.bash \
                  --name user-stage.bash \
    && chmod 755 /tmp/user-stage.bash

/tmp/root-stage.bash
runuser -u opc /tmp/user-stage.bash
runuser -u opc id > /tmp/id.txt
