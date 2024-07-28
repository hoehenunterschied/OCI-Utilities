#!/usr/bin/env bash

# search restricted to compartment
COMPARTMENT_NAME="<insert a compartment name here>"

# search restricted to resource types
# https://docs.oracle.com/en-us/iaas/Content/Search/Concepts/queryoverview.htm#resourcetypes
RESOURCE_TYPE_LIST="instance,autonomousdatabase"

# select values that identify resources created by yourself
TAG_NAMESPACE="<insert a tag namespace here>"
TAG_KEY="<insert a tag key here>"
USER="john.doe@acme.com"

# ADAPT THE OCIPROFILE AND ACTIVATON OF THE PYTHON VIRTUAL
# ENVIRONMENT for the OCI CLI TO YOUR INSTALLATION
# see https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/climanualinst.htm#
OCIPROFILE="DEFAULT"
OCIOPTIONS="--profile ${OCIPROFILE} --cli-rc-file /dev/null"

# do not change value if set in environment
DEBUG_PRINT="${DEBUG_PRINT:=false}"

# filename of this script
THIS_SCRIPT="$(basename ${BASH_SOURCE})"

debug_print()
{
  if [[ "${DEBUG_PRINT}" = true ]]; then
    echo -e "$*"
  fi
}

usage()
{
  echo -e "\nUsage:"
  echo -e "========"
  echo -e "           list instances and autonomous databases : ${THIS_SCRIPT}"
  echo -e "                      list selected resource types : ${THIS_SCRIPT} <resource list>"
  echo -e ""
  echo -e "  Example for <resource list> : instance,autonomousdatabase,vnic\n"
  echo -e "  For possible resource types, see"
  echo -e "  https://docs.oracle.com/en-us/iaas/Content/Search/Concepts/queryoverview.htm#resourcetypes"
  echo -e ""
  exit
}

case "$#" in
  "0")
    RESOURCE_TYPES="${RESOURCE_TYPE_LIST}"
    ;;
  "1")
    RESOURCE_TYPES="$1"
    ;;
  *)
    usage
    ;;
esac

# oci cli must work after this section
# if oci cli is not setup via a Python virtual environment,
# this section can be commented out.
OCICLI_DIR="${HOME}/tmp/oracle-cli/bin"
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

TAG_VALUE="oracleidentitycloudservice/${USER}"

COMPARTMENT_ID=$(oci ${OCIOPTIONS} search resource structured-search \
  --raw-output \
  --query-text "query compartment resources
                  where displayName=='${COMPARTMENT_NAME}'" \
  --query "data.items[0].identifier")

oci ${OCIOPTIONS} search resource structured-search --limit 5000 \
  --query-text "query ${RESOURCE_TYPES} resources 
                  where (
                       definedTags.namespace='${TAG_NAMESPACE}'
                    && definedTags.key='${TAG_KEY}'
                    && definedTags.value='${TAG_VALUE}'
                    && compartmentID=='${COMPARTMENT_ID}'
                  )" \
  --query "sort_by(data.items[],&\"resource-type\")
           | [].{type:\"resource-type\",
                 ocid:identifier,
                 state:\"lifecycle-state\",
                 name:\"display-name\"}" \
  --output table
