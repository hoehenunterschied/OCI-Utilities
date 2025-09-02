#!/usr/bin/env bash
# convert this file with
#  cat <filename> | base64 --wrap 0
# and put it as user_data in the launch script
exec > /tmp/root-setup-output.txt 2>&1

source /etc/os-release
if [[ "$NAME" == "Oracle Linux Server" ]]; then
  if [[ "$VERSION_ID" == 8* ]]; then
    echo "### Oracle Linux 8"
    echo "### dnf install oraclelinux-developer-release-el8"
    dnf install oraclelinux-developer-release-el8
    echo "### dnf install oracle-epel-release-el8"
    dnf install oracle-epel-release-el8
    echo "### dnf -y config-manager --enable ol8_developer_EPEL"
    dnf -y config-manager --enable ol8_developer_EPEL
  elif [[ "$VERSION_ID" == 9* ]]; then
    echo "### Oracle Linux 9"
    echo "### dnf install oraclelinux-developer-release-el9"
    dnf install oraclelinux-developer-release-el9
    echo "### dnf install oracle-epel-release-el9"
    dnf install oracle-epel-release-el9
    echo "### dnf -y config-manager --enable ol9_developer_EPEL"
    dnf -y config-manager --enable ol9_developer_EPEL
  elif [[ "$VERSION_ID" == 10* ]]; then
    echo "### Oracle Linux 10"
    echo "### dnf install oraclelinux-developer-release-el10"
    dnf install oraclelinux-developer-release-el10
    echo "### dnf install oracle-epel-release-el10"
    dnf install oracle-epel-release-el10
    echo "### dnf -y config-manager --enable ol10_u0_developer_EPEL"
    dnf -y config-manager --enable ol10_u0_developer_EPEL
  else
    echo "### version not supported: $VERSION_ID"
    exit
  fi
else
  echo "### OS not supported: $NAME"
  exit
fi

# install tmux, git, htop and Eternal Terminal
echo "### dnf -y install tmux"
          dnf -y install tmux
echo "### dnf -y install git"
          dnf -y install git           
echo "### dnf -y install htop"
          dnf -y install htop     
echo "### dnf -y install et"
          dnf -y install et
echo "### systemctl --now enable et"
systemctl --now enable et

echo "### INSTANCE_NAME=\"\$(curl -s -H \"Authorization: Bearer Oracle\" http://169.254.169.254/opc/v2/instance/displayName)\""
INSTANCE_NAME="$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/displayName)"
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  echo "### dnf -y install httpd"
  dnf -y install httpd
  echo "### systemctl --now enable httpd"
  systemctl --now enable httpd
fi

if [[ "$VERSION_ID" == 10* ]]; then
    echo "### dnf -y config-manager --disable ol10_u0_developer_EPEL"
    dnf -y config-manager --disable ol10_u0_developer_EPEL
fi


echo "### the firewall configuration"
echo "### systemctl start firewalld"
          systemctl start firewalld

# schedule a job to execute some firewall-cmd
echo "### ATJOB_FILE="/usr/local/bin/atjob.bash""
ATJOB_FILE="/usr/local/bin/atjob.bash"
echo "### cat > \"\${ATJOB_FILE}\" << EOF"
cat > "${ATJOB_FILE}" << EOF
#!/usr/bin/env bash

exec >> /tmp/atjob-output.txt 2>&1

echo "### $(date +"%Y%m%d-%T")"
EOF
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  echo "### echo \"firewall-cmd --permanent --zone=public --add-port=80/tcp\" >> \"\${ATJOB_FILE}\""
  echo "echo \"### firewall-cmd --permanent --zone=public --add-port=80/tcp\"" >> "${ATJOB_FILE}"
  echo "firewall-cmd --permanent --zone=public --add-port=80/tcp" >> "${ATJOB_FILE}"
fi
echo "### echo \"firewall-cmd --permanent --zone=public --add-port=2022/tcp\" >> \"\${ATJOB_FILE}\""
echo "echo \"### firewall-cmd --permanent --zone=public --add-port=2022/tcp\"" >> "${ATJOB_FILE}"
echo "firewall-cmd --permanent --zone=public --add-port=2022/tcp" >> "${ATJOB_FILE}"
echo "echo \"### firewall-cmd --reload\"" >> "${ATJOB_FILE}"
echo "### echo \"firewall-cmd --reload\" >> \"\${ATJOB_FILE}\""
echo "firewall-cmd --reload" >> "${ATJOB_FILE}"
echo "### chmod +x "${ATJOB_FILE}""
chmod +x "${ATJOB_FILE}"

SERVICE_FILE="/etc/systemd/system/from-boot-init.service"
echo "### cat > \"\${SERVICE_FILE}\" << EOF"
cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=Run my job

[Service]
Type=oneshot
ExecStart=${ATJOB_FILE}
EOF
echo "### systemctl daemon-reload"
systemctl daemon-reload
echo "### systemctl start from-boot-init.service"
systemctl start from-boot-init.service

echo "### root-setup.bash finished"
