#!/usr/bin/env bash

USER_HOME="/home/opc"
USERANDGROUP="opc:opc"
TMUX_SCRIPT="tmux-default.bash"
LESS_SCRIPT="osmh-logs.bash"
OCI_CONNECTIVITY_SCRIPT="oci-connectivity.bash"

# determine operating system version
if [ -f /etc/oracle-release ]; then
    release_info=$(cat /etc/oracle-release)
elif [ -f /etc/os-release ]; then
    release_info=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
    echo "Cannot determine Oracle Linux version"
fi

if [[ "$release_info" == *"8."* || "$release_info" == "8" ]]; then
#
# Oracle Linux 8
#
    FIXPATHIN=".bashrc"
    dnf install oraclelinux-developer-release-el8
    dnf install oracle-epel-release-el8
    dnf -y config-manager --enable ol8_developer_EPEL
    dnf -y install tmux git htop
    dnf -y install python36-oci-cli
elif [[ "$release_info" == *"9."* || "$release_info" == "9" ]]; then
#
# Oracle Linux 9
#
    FIXPATHIN=".bashrc"
    dnf install oraclelinux-developer-release-el9
    dnf install oracle-epel-release-el9
    dnf -y config-manager --enable ol9_developer_EPEL
    dnf -y install tmux git htop
    dnf -y install python39-oci-cli
else
    echo "Unknown or unsupported Oracle Linux version: $release_info"
fi

INSTANCE_NAME="$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/displayName)"

dnf -y install et
if [ "${INSTANCE_NAME}" = "frankfurt" ]; then
  NSGS+=('HTTP')
  dnf -y install httpd
  systemctl --now enable httpd
  firewall-cmd --permanent --zone=public --add-port=80/tcp
fi
systemctl --now enable et
firewall-cmd --permanent --zone=public --add-port=2022/tcp
firewall-cmd --reload

sed --in-place=.bak -e 's/\$HOME\/bin/$HOME\/.bin/' "${USER_HOME}"/"${FIXPATHIN}"
mkdir "${USER_HOME}/.bin" && chown "${USERANDGROUP}" "${USER_HOME}"/.bin

cat >> "${USER_HOME}"/.bash_profile << EOF
if [[ -z \$TMUX ]] && [[ -n \$SSH_TTY ]]; then
	  "\${HOME}"/.bin/"${TMUX_SCRIPT}"
fi
EOF

#chmod ug+x "${USER_HOME}"/.bin/"${OCI_CONNECTIVITY_SCRIPT}"
#chown "${USERANDGROUP}" "${USER_HOME}"/.bin/"${OCI_CONNECTIVITY_SCRIPT}"

cd "${USER_HOME}"
git clone --single-branch https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
sed --in-place=.bak -e 's/^#set -g mouse on/set -g mouse on/' "${USER_HOME}"/.tmux.conf.local
chown -R "${USERANDGROUP}" "${USER_HOME}"/.tmux
chown "${USERANDGROUP}" "${USER_HOME}"/.tmux.conf
chown "${USERANDGROUP}" "${USER_HOME}"/.tmux.conf.local
chown "${USERANDGROUP}" "${USER_HOME}"/.tmux.conf.local.bak
