# Boot Init Script

When a compute instance is created with a boot-init script provided, the script is executed after provisioning. 

`launch-instance.bash` takes a list of names as parameters and creates compute instances with those names. Before running the script, edit the veariables `COMPARTMENT_NAME`, `VCN_NAME`, `SUBNET_NAME`, `AVAILABILITY_DOMAIN_NUMBER` and `SSH_AUTHORIZED_KEYS` to suit your environment.<br>
The script retrieves the OCIDs for the tenancy, compartment, VCN, subnet, the latest available image and the name of the availability domain through OCI CLI calls.<br>
To retrieve the source code of the `boot-init` File, pipe the value of the `user_data` parameter to `base64 --decode`.
The `boot-init` script provided in `launch-instance.bash` enables another yum repository, installs `git`, `htop` and `tmux`, creates the directory `/home/opc/.bin`, puts the script `tmux-default.bash` into `/home/opc/.bin` and alters `.bash_profile` and `.bashrc` of the user `opc` to include `/home/opc/.bin` into the `PATH` environment variable and to call `~opc/.bin/tmux-default.bash` for interactive logins.