#!/usr/bin/env bash

# avoid reading ~/.oci/oci_cli_rc
OCIOPTIONS="--cli-rc-file /dev/null"

# params.txt must define these variables
# OCICLI_DIR
# COMPARTMENT_ID
# RESOURCES_TO_PROCESS
# RESOURCE_LIST_DIR
# RESOURCE_LIST_FILE_NAME
# TAG_DIRECTORY

# make sure params.txt is found if script is called from other directory
PARAMETER_FILE="$(dirname "$(realpath "$0")")/params.txt"
if [ ! -f "${PARAMETER_FILE}" ]; then
  echo -e "\n### parameter file \"${PARAMETER_FILE}\" not found. Exiting.\n"
  exit
fi
source "${PARAMETER_FILE}"

# do not change value if set in environment
DEBUG_PRINT="${DEBUG_PRINT:=false}"

debug_print()
{
  if [[ "${DEBUG_PRINT}" = true ]]; then
    echo -e "$*"
  fi
}

# Begin OCI setup
#
# OCICLI_DIR is read from params.txt
# if OCICLI_DIR is set, use oci from there if it exists
if [ ! -z "${OCICLI_DIR+x}" ] && [ -r "${OCICLI_DIR}/bin/activate" ] && [ -x "${OCICLI_DIR}/bin/oci" ]; then
  debug_print "### activate VENV from $OCICLI_DIR"
  source "${OCICLI_DIR}/bin/activate"
fi
if $(which oci 2>&1 > /dev/null); then
  debug_print "### using $(which oci)"
else
  echo -e "###\n### oci not found.### exiting\n###"
  echo -e "### see https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm\n### to install OCI CLI"
fi
# End OCI setup

CHECK_DIRS=()
CHECK_DIRS+=("${TAG_DIRECTORY}")
#CHECK_DIRS+=("${RESOURCE_LIST_DIR}")
for dir in "${CHECK_DIRS[@]}"; do
  if [ ! -w "${dir}" ]; then
    mkdir -p "${dir}"
    if [ ! -w "${dir}" ]; then
      echo "### unable to create or write to ${dir}"
      echo "### exiting"
      exit
    fi
  fi
done

TMP_LIST=$(oci search resource structured-search \
  --query-text "query ${RESOURCES_TO_PROCESS} resources
                   where compartmentID='${COMPARTMENT_ID}'
                         && lifecycleState!='TERMINATED'" \
  --raw-output \
  --query "join(' ', sort_by(data.items, &\"resource-type\")[].identifier)")
OCID_LIST=($(echo $TMP_LIST))

#OCID_LIST=($(jq --raw-output ".[].id" resource-list.json))
for ocid in "${OCID_LIST[@]}"; do
  case $ocid in
    ocid1.instance.*)
      OCICLI_PART="compute instance get --instance-id"
      ;;
    ocid1.bootvolume.*)
      OCICLI_PART="bv boot-volume get --boot-volume-id"
      ;;
    ocid1.vnic.*)
      OCICLI_PART="network vnic get --vnic-id"
      ;;
    ocid1.subnet.*)
      OCICLI_PART="network subnet get --subnet-id"
      ;;
    ocid1.dbsystem.*)
      OCICLI_PART="db system get --db-system-id"
      ;;
    ocid1.autonomousdatabase.*)
      OCICLI_PART="db autonomous-database get --autonomous-database-id"
      ;;
    *)
      ### dot-printing-only echo -en "\ncan't process $ocid"
      ### dot-printing-only NEEDCR="\\n"
      echo -e "--> ERROR: resource type not supported for $ocid"
      continue
  esac
  ### dot-printing-only echo -en "${NEEDCR}."
  ### dot-printing-only NEEDCR=""
  if oci ${OCICLI_PART} ${ocid} --query "data.\"defined-tags\"" > "${TAG_DIRECTORY}/${ocid}"; then
    echo -e "    saved Defined Tags for $ocid"
  else
    rm -f "${TAG_DIRECTORY}/${ocid}"
    echo -e ">>>>>>\n--> ERROR processing $ocid"
    oci ${OCICLI_PART} ${ocid} --query "data.\"defined-tags\""
    echo -e "<<<<<<"
  fi
done
### dot-printing-only echo ""
