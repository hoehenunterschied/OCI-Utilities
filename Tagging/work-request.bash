#!/usr/bin/env bash

# avoid reading ~/.oci/oci_cli_rc
OCIOPTIONS="--cli-rc-file /dev/null"

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

usage() {
  echo -e "\nUsage : $(basename $0) [<tagging-work-request-id>]\n"
}

if [ "$#" -gt 1 ]; then
  echo -e "\n### illegal number of parameters"
  usage
  exit
fi

if [ "$#" -eq 0 ]; then
  TAGGING_WORK_REQUEST_ID=$(oci ${OCIOPTIONS} iam tagging-work-request list \
  --all \
  --compartment-id "${COMPARTMENT_ID}" \
  --raw-output \
  --query "reverse(sort_by(data, &\"time-accepted\"))[0].id"
  )
else
  TAGGING_WORK_REQUEST_ID="$1"
fi
debug_print "### TAGGING_WORK_REQUEST_ID : $TAGGING_WORK_REQUEST_ID"

if [[ "$TAGGING_WORK_REQUEST_ID" != ocid1.taggingworkrequest.oc1.* ]]; then
  echo -e "\n### tagging work request id has wrong format\n"
  exit
fi
oci ${OCIOPTIONS} iam tagging-work-request get --work-request-id "${TAGGING_WORK_REQUEST_ID}"
