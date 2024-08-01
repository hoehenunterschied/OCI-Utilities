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
