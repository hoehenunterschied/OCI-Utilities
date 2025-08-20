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

if [[ "$release_info" == *"7."* || "$release_info" == "7" ]]; then
    cat > /etc/yum.repos.d/epel-yum-ol7.repo << EOF
[ol7_epel]
name=Oracle Linux \$releasever EPEL (\$basearch)
baseurl=http://yum.oracle.com/repo/OracleLinux/OL7/developer_EPEL/\$basearch/
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-oracle
gpgcheck=1
enabled=1
EOF
    yum install -y tmux git htop
elif [[ "$release_info" == *"8."* || "$release_info" == "8" ]]; then
    echo "Oracle Linux 8 detected"
    dnf -y config-manager --enable ol8_developer_EPEL
    dnf -y install tmux git htop
elif [[ "$release_info" == *"9."* || "$release_info" == "9" ]]; then
    dnf -y config-manager --enable ol9_developer_EPEL
    dnf -y install tmux git htop
else
    echo "Unknown or unsupported Oracle Linux version: $release_info"
fi


sed --in-place=.bak -e 's/\$HOME\/bin/$HOME\/.bin/' "${USER_HOME}"/.bashrc
mkdir "${USER_HOME}/.bin" && chown "${USERANDGROUP}" "${USER_HOME}"/.bin

cat > "${USER_HOME}/.bin/${TMUX_SCRIPT}" << EOF
#!/usr/bin/env bash
if [ ! -d "\${HOME}/tmp" ]; then
  mkdir "\${HOME}/tmp"
fi
cd "\${HOME}/tmp"
tmux has-session -t "\$(hostname)" && tmux attach-session -t "\$(hostname)" || tmux new-session -s "\$(hostname)"\; \\
     split-window -h \; \\
     send-keys 'htop' C-m\; \\
     split-window -v\; \\
     select-pane -t 1\;
EOF
chmod ug+x "${USER_HOME}"/.bin/"${TMUX_SCRIPT}"
chown "${USERANDGROUP}" "${USER_HOME}"/.bin/"${TMUX_SCRIPT}"

cat >> "${USER_HOME}"/.bash_profile << EOF
if [[ -z \$TMUX ]] && [[ -n \$SSH_TTY ]]; then
	  "\${HOME}"/.bin/"${TMUX_SCRIPT}"
fi
EOF

cat > "${USER_HOME}/.bin/${LESS_SCRIPT}" << EOF
#!/usr/bin/env bash
sudo less \\
  /var/lib/oracle-cloud-agent/plugins/oci-osmh/osmh-agent/stateDir/log/osmh-agent.log \\
  /var/log/oracle-cloud-agent/plugins/oci-osmh/oci-osmh.log \\
  /var/log/oracle-cloud-agent/agent.log
EOF
chmod ug+x "${USER_HOME}"/.bin/"${LESS_SCRIPT}"
chown "${USERANDGROUP}" "${USER_HOME}"/.bin/"${LESS_SCRIPT}"

cat > "${USER_HOME}/.bin/${OCI_CONNECTIVITY_SCRIPT}" << EOF
#!/usr/bin/env bash

tempfile=\$(mktemp)
echo "Temporary file created: \$tempfile"

curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/regionInfo > "\${tempfile}"
export REGION=\$(cat "\${tempfile}" | jq -r ".regionIdentifier")
export DOMAIN=\$(cat "\${tempfile}" | jq -r ".realmDomainComponent")
curl -s https://osmh."\${REGION}".oci."\${DOMAIN}" &>/dev/null ; [ \$? == 0 ] && echo "Success" || echo "Failure"
rm "\${tempfile}"
EOF
chmod ug+x "${USER_HOME}"/.bin/"${OCI_CONNECTIVITY_SCRIPT}"
chown "${USERANDGROUP}" "${USER_HOME}"/.bin/"${OCI_CONNECTIVITY_SCRIPT}"

cd "${USER_HOME}"
git clone --single-branch https://github.com/gpakosz/.tmux.git
ln -s -f .tmux/.tmux.conf
cp .tmux/.tmux.conf.local .
sed --in-place=.bak -e 's/^#set -g mouse on/set -g mouse on/' "${USER_HOME}"/.tmux.conf.local
chown -R "${USERANDGROUP}" "${USER_HOME}"/.tmux
chown "${USERANDGROUP}" "${USER_HOME}"/.tmux.conf
chown "${USERANDGROUP}" "${USER_HOME}"/.tmux.conf.local
chown "${USERANDGROUP}" "${USER_HOME}"/.tmux.conf.local.bak
