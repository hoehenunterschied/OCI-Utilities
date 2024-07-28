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
# OPERATIONS_FILE

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
#CHECK_DIRS+=("${TAG_DIRECTORY}")
CHECK_DIRS+=("${RESOURCE_LIST_DIR}")
for dir in "${CHECK_DIRS[@]}"; do
  if [ ! -w "${dir}" ]; then
    debug_print "directory ${dir} not writable, trying to create it"
    mkdir -p "${dir}"
    if [ ! -w "${dir}" ]; then
      echo "### unable to create or write to ${dir}"
      echo "### exiting"
      exit
    fi
  fi
done

# check if OPERATIONS_FILE, defined in parameter file, exists
OPS_FILE="$(dirname "$(realpath "$0")")/${OPERATIONS_FILE}"
debug_print "### OPS_FILE : $OPS_FILE"
CHECK_FILES=()
CHECK_FILES+=("${OPS_FILE}")
for file in "${CHECK_FILES[@]}"; do
  if [ ! -f "${file}" ]; then
    echo -e "\n### parameter file \"${file}\" not found. Exiting.\n"
    exit
  fi
done

# create resource list for bulk tag update
oci search resource structured-search \
  --query-text "query ${RESOURCES_TO_PROCESS} resources
                   where compartmentID='${COMPARTMENT_ID}'
                         && lifecycleState!='TERMINATED'" \
  --query 'data.items[].{id:identifier,
                         "resourceType":"resource-type"}' \
  > "${RESOURCE_LIST_DIR}/${RESOURCE_LIST_FILE_NAME}"

#echo oci iam tag bulk-edit --compartment-id "${COMPARTMENT_ID}" --resources file://"${RESOURCE_LIST_DIR}/${RESOURCE_LIST_FILE_NAME}" --bulk-edit-operations file://"${OPS_FILE}"
oci iam tag bulk-edit \
  --compartment-id "${COMPARTMENT_ID}" \
  --resources file://"${RESOURCE_LIST_DIR}/${RESOURCE_LIST_FILE_NAME}" \
  --bulk-edit-operations file://"${OPS_FILE}"
