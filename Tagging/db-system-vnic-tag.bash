#!/usr/bin/env bash

# avoid reading ~/.oci/oci_cli_rc
OCIOPTIONS="--cli-rc-file /dev/null"

# params.txt must define these variables
# OCICLI_DIR
# COMPARTMENT_ID
# DISPLAY_NAME

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

DB_SYSTEM_ID=$(oci db system list \
                 --compartment-id "${COMPARTMENT_ID}" \
                 --raw-output \
                 --query "data[?\"lifecycle-state\"=='AVAILABLE'
                             && \"display-name\"=='${DISPLAY_NAME}']
                          | [0].id")

VNIC_ID=$(oci db node list --compartment-id "${COMPARTMENT_ID}" \
                 --db-system-id "${DB_SYSTEM_ID}" \
                 --raw-output \
                 --query "data[0].\"vnic-id\"")
debug_print "DB_SYSTEM_ID : $DB_SYSTEM_ID"
debug_print "     VNIC_ID : $VNIC_ID"

echo -e "###\n### Defined Tags of DB System ${DB_SYSTEM_ID}\n###"
oci db system get --db-system-id "${DB_SYSTEM_ID}" --query "data.\"defined-tags\""
echo -e "Press RETURN to show Defined Tags of the VNIC\n"
read

echo -e "###\n### Defined Tags of VNIC ${VNIC_ID}\n###"
oci network vnic get --vnic-id "${VNIC_ID}" --query "data.\"defined-tags\""
echo -e "Press RETURN to update Defined Tags of the DB System\n"
read

echo -e "###\n### Defined Tags of DB System after update\n###"
oci db system update --force --db-system-id "${DB_SYSTEM_ID}" --defined-tags '{}' --query "data.\"defined-tags\""
echo -e "Press RETURN to try to update the VNIC Defined Tags. This will fail.\n"
read

echo -e "###\n### Trying to update Defined Tags of VNIC\n###"
oci network vnic update --force --vnic-id "${VNIC_ID}" --defined-tags '{}'

