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
# DEFINED_TAGS_FILE

# make sure params.txt is found if script is called from other directory
PARAMETER_FILE="$(dirname "$(realpath "$0")")/params.txt"
if [ ! -f "${PARAMETER_FILE}" ]; then
  echo -e "\n### parameter file \"${PARAMETER_FILE}\" not found. Exiting.\n"
  exit
fi
source "${PARAMETER_FILE}"

# filename of this script
THIS_SCRIPT="$(basename ${BASH_SOURCE})"

# do not change value if set in environment
DEBUG_PRINT="${DEBUG_PRINT:=false}"

debug_print()
{
  if [[ "${DEBUG_PRINT}" = true ]]; then
    echo -e "$*"
  fi
}

usage()
{
echo -e "\nUsage:"
echo -e "======"
echo -e ""
echo -e "       restore defined tags from backup : ${THIS_SCRIPT} restore"
echo -e "                    remove defined tags : ${THIS_SCRIPT} clear"
echo -e "   apply same defined tags to resources : ${THIS_SCRIPT} fromfile"
echo -e ""
echo -e "When ${THIS_SCRIPT} is executed with the fromfile option,"
echo -e "defined tag definitions are read from ${DEFINED_TAGS_FILE}"
}

if [[ $# -ne 1 ]]; then
  usage
  exit
fi
ACTION="$1"
case "${ACTION}" in
  restore)
    echo "restoring defined tags from backup directory ${TAG_DIRECTORY}"
    PRINT_VERB="restored"
    TAG_ARGUMENT="file://\"\${TAG_DIRECTORY}/\${ocid}\""
    ;;
  clear)
    echo "setting defined tags to \"{}\""
    PRINT_VERB="cleared"
    TAG_ARGUMENT="\"{}\""
    ;;
  fromfile)
    echo "setting all defined tags from ${DEFINED_TAGS_FILE}"
    PRINT_VERB="wrote"
    TAG_ARGUMENT="file://\"\${DEFINED_TAGS_FILE}\""
    ;;
  *)
    echo -e "\n### unknown parameter \"$ACTION\"."
    usage
    exit
esac

# Begin VENV setup
# ensure we have a virtual environment
# OCICLI_DIR is read from params.txt
if [ -z "${VIRTUAL_ENV}" ]; then
  debug_print "### virtual environment is unset"
  if [ -d "${OCICLI_DIR}" ]; then
    debug_print "### $OCICLI_DIR exists"
    if [ -f "${OCICLI_DIR}/activate" ]; then
      debug_print "### sourcing ${OCICLI_DIR}/activate"
      source "${OCICLI_DIR}/activate"
    else
      echo "### No virtual environment and ${OCICLI_DIR}/activate does not exist. Exiting."
      exit
    fi
  else
    echo "### directory ${OCICLI_DIR} not found. Exiting."
    exit
  fi
else
  if [ ! -d "${VIRTUAL_ENV}" ]; then
    echo "### VIRTUAL_ENV ist set, but directory for virtual environment not found. Exiting."
    exit
  fi
fi
debug_print "### virtual environment : ${VIRTUAL_ENV}"
# End VENV setup

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

CHECK_FILES=()
CHECK_FILES+=("${DEFINED_TAGS_FILE}")
for file in "${CHECK_FILES[@]}"; do
  if [ ! -f "${file}" ]; then
    echo -e "\n### parameter file \"${file}\" not found. Exiting.\n"
    exit
  fi
done

## create resource list for bulk tag update
#oci search resource structured-search \
#  --query-text "query ${RESOURCES_TO_PROCESS} resources
#                   where compartmentID='${COMPARTMENT_ID}'
#                         && lifecycleState!='TERMINATED'" \
#  --query 'data.items[].{id:identifier,
#                         "reource-type":"resource-type"}' \
#  > "${RESOURCE_LIST_DIR}/${RESOURCE_LIST_FILE_NAME}"


TMP_LIST=$(oci search resource structured-search \
  --query-text "query ${RESOURCES_TO_PROCESS} resources
                   where compartmentID='${COMPARTMENT_ID}'
                         && lifecycleState!='TERMINATED'" \
  --raw-output \
  --query "join(' ', sort_by(data.items, &\"resource-type\")[].identifier)")
OCID_LIST=($(echo $TMP_LIST))
# alternative, but depends on jq
#OCID_LIST=($(jq --raw-output ".[].id" resource-list.json))

for ocid in "${OCID_LIST[@]}"; do
  case $ocid in
    ocid1.instance.*)
      OCICLI_PART="compute instance update --instance-id"
      ;;
    ocid1.bootvolume.*)
      OCICLI_PART="bv boot-volume update --boot-volume-id"
      ;;
    ocid1.vnic.*)
      OCICLI_PART="network vnic update --vnic-id"
      ;;
    ocid1.subnet.*)
      OCICLI_PART="network subnet update --subnet-id"
      ;;
    ocid1.dbsystem.*)
      OCICLI_PART="db system update --db-system-id"
      ;;
    ocid1.autonomousdatabase.*)
      OCICLI_PART="db autonomous-database update --autonomous-database-id"
      ;;
    *)
      echo -e "### can't process $ocid"
      continue
  esac
  #oci ${OCICLI_PART} ${ocid} --query "data.\"defined-tags\"" > "${TAG_DIRECTORY}/${ocid}"

  # only change tags if backup file exists
  if [ -f "${TAG_DIRECTORY}/${ocid}" ]; then
    OUTPUT=$(eval oci ${OCICLI_PART} ${ocid} --force --defined-tags ${TAG_ARGUMENT} 2>&1)
    if [[ $? -eq 0 ]]; then
      echo "    ${PRINT_VERB} tags of $ocid"
    else
      echo -e ">>>>>>\n--> ERROR processing $ocid\n$OUTPUT\n<<<<<<"
    fi
  else
    echo "### ERROR: did not find tag backup for $ocid"
  fi


done
