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
  else
    echo "### version not supported: $VERSION_ID"
    exit
  fi
else
  echo "### OS not supported: $NAME"
  exit
fi

# install tmux, git, htop and Eternal Terminal
echo "### dnf -y install tmux git htop et"
dnf -y install tmux git htop et
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

echo "### the firewall configuration"
echo "### systemctl start firewalld"
          systemctl start firewalld
echo "### root-setup.bash finished"
## do this in the user-setup script to give
## the firewalld even more time
#if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
#  echo "### firewall-cmd --permanent --zone=public --add-port=80/tcp"
#            firewall-cmd --permanent --zone=public --add-port=80/tcp
#fi
#echo "### firewall-cmd --permanent --zone=public --add-port=2022/tcp"
#          firewall-cmd --permanent --zone=public --add-port=2022/tcp
#echo "### firewall-cmd --reload"
#          firewall-cmd --reload

