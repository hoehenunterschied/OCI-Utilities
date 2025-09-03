
###############################
### Prerequisites
###############################
oci must be installed on your local computer
oci must work without specifying --compartment-id all the time
COMPARTMENT_NAME must exist
VCN_NAME, SUBNET_NAME must exist in COMPARTMENT_NAME
AVAILABILITY_DOMAIN_NUMBER must be '1' in single AD regions, 1, 2 or 3 in 3 AD regions
instances get a public IP address
load the scripts root-setup.bash, user-setup.bash and the scripts referenced by FILE[@] in user-setup.bash into the bucket BUCKET_NAME. You can use the file upload-instance-script.bash for uploading.

###############################
### Runs on local computer
###############################

launch_instance.bash
====================
NAME, OS, CPU
OCPUS
MEMORY_IN_GBS
COMPARTMENT_NAME
VCN_NAME
SUBNET_NAME
AVAILABILITY_DOMAIN_NUMBER
BUCKET_NAME
FILE_LIST

upload-instance-script.bash
===========================
BUCKET_NAME

check_md5.bash
==============
BUCKET_NAME
FILE_LIST

###############################
### Runs on the OCI instance
###############################

boot-init.bash
==============
OCI_CLI_AUTH
BUCKET_NAME
/tmp/root-setup.bash
/tmp/user-setup.bash
/tmp/id.txt <-- is not needed

root-setup.bash
===============

user-setup.bash
===============
comment out the parts that use DNSHOSTNAME, DNSDOMAIN
VCN
BUCKET_NAME
FILE(), LOCATION(), PERMS()
NSGS
