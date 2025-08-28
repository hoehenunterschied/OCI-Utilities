#!/usr/bin/env bash

# filename of this script
THIS_SCRIPT="$(basename ${BASH_SOURCE})"

# avoid reading ~/.oci/oci_cli_rc
OCIOPTIONS="--cli-rc-file /dev/null"

# params.txt must define some variables
# OCICLI_DIR
# COMPARTMENT_ID takes precedence over COMPARTMENT_NAME if set
# COMPARTMENT_NAME
# TAG_NAMESPACE
# TAG_KEY
# TAG_VALUE
# RESOURCES_TO_PROCESS
# see usage()


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
debug_print "### oci virtual environment: $VIRTUAL_ENV"

usage()
{
echo -e "\nUsage:\n======"
echo -e "                   no action, show list of resources in compartment: ${THIS_SCRIPT}"
echo -e "                         no action, display resources matching name: ${THIS_SCRIPT} <name>"
echo -e "                         start/stop resources matching defined tags: ${THIS_SCRIPT} start|stop"
echo -e "                                 start/stop resources matching name: ${THIS_SCRIPT} <name> start|stop"
echo -e ""
echo -e "  ${THIS_SCRIPT} reads the parameter file params.txt which needs to provide these values:"
echo -e "    - OCICLI_DIR : location of OCI CLI installation"
echo -e "    - COMPARTMENT_NAME : the compartment to work on. If the name is not unique,"
echo -e "                         the script uses the first compartment with matching name returned by search"
echo -e "    - TAG_NAMESPACE : start and stop act on matching resources when no name parameter is given."
echo -e "    - TAG_KEY"
echo -e "    - TAG_VALUE"
echo -e "    - RESOURCES_TO_PROCESS can be instance,dbnode,autonomousdatabase"
exit
}

if [ "$#" -gt 2 ]; then
  echo -e "\n### too many parameters\n"
  usage
fi

oldIFS="${IFS}"
IFS=","
TYPE_LIST=($RESOURCES_TO_PROCESS)
IFS="${oldIFS}"
debug_print "### types to process:\n### >>>"
for f in "${TYPE_LIST[@]}"; do
  debug_print "###    $f"
done
debug_print "### <<<"

# get the compartment to work in
# if COMPARTMENT_ID is set and looks like having the correct
# format, go with it. Otherwise look for COMPARTMENT_NAME
# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
if [ ! -z ${COMPARTMENT_ID+x} ]; then
  case "${COMPARTMENT_ID}" in
  ocid1.compartment.oc1..* | ocid1.tenancy.oc1..* )
    debug_print "### COMPARTMENT_ID is set. Using it"
    ;;
  *)
    echo "COMPARTMENT_ID is set, but has wrong format"
    echo "COMPARTMENT_ID : \"${COMPARTMENT_ID}\""
    echo "Now trying COMPARTMENT_NAME"
    unset COMPARTMENT_ID
  esac
fi
if [ -z ${COMPARTMENT_ID+x} ]; then
  debug_print "### using COMPARTMENT_NAME \"${COMPARTMENT_NAME}\""
  COMPARTMENT_ID=$(oci ${OCIOPTIONS} search resource structured-search \
    --raw-output \
    --query-text "query compartment resources
                    where displayName=='${COMPARTMENT_NAME}'" \
    --query "data.items[0].identifier")
  if [ "${COMPARTMENT_ID}" = "" ]; then
    echo "compartment \"${COMPARTMENT_NAME}\" not found"
    exit
  fi
fi
debug_print "### compartment_id: $COMPARTMENT_ID"

process_nodes()
{
  debug_print "in process_nodes(action=$1, ocid=$2)"
  case "$1" in
    start)
      LIFECYCLE_EXPR="&&\"lifecycle-state\"=='STOPPED'"
      ;;
    stop)
      LIFECYCLE_EXPR="&&\"lifecycle-state\"=='AVAILABLE'"
      ;;
    *)
      echo "### unknown action \"$1\", continuing."
      return
  esac
  oci db node list \
    --raw-output \
    --output table \
    --db-system-id "${2}" \
    --compartment-id "${COMPARTMENT_ID}" \
    --query "sort_by(data[?!contains(\"lifecycle-state\",'TERMINAT')
                          ${LIFECYCLE_EXPR}],&hostname)[].{\"1 hostname\":hostname,
                                                           \"2 lifecycle-state\":\"lifecycle-state\",
                                                           \"3 ocid\":id}"
  TMP_LIST=$(oci db node list \
    --raw-output \
    --db-system-id "${2}" \
    --compartment-id "${COMPARTMENT_ID}" \
    --query "join(' ',data[?!contains(\"lifecycle-state\",'TERMINAT')${LIFECYCLE_EXPR}].id)")
  OCID_LIST=(${TMP_LIST})
  for ocid in "${OCID_LIST[@]}"; do
    echo oci ${OCIOPTIONS} db node $1 --db-node-id ${ocid}
    OUTPUT=$(oci ${OCIOPTIONS} db node $1 --db-node-id ${ocid} --raw-output --query "\"opc-work-request-id\"")
    if [[ "${OUTPUT}" != ocid1.coreservicesworkrequest.oc1.* ]]; then
      echo "### error performing $1 on ${ocid}: $OUTPUT"
    fi
  done
}

process_resources()
{
  echo "in process_resources(type=\"$1\", action=\"$2\", name=\"$3\")"
  # $1: resource type, $2: action, $3: name
  case "$2" in
    start)
      LIFECYCLE_EXPR="&&\"lifecycle-state\"=='STOPPED'"
      ;;
    stop)
      LIFECYCLE_EXPR="&&(\"lifecycle-state\"=='RUNNING'||\"lifecycle-state\"=='AVAILABLE')"
      ;;
    *)
      echo "### Unknown action \"$2\". Continuing."
  esac
  if [ "${1}" = "dbsystem" ]; then
    LIFECYCLE_EXPR="&&\"lifecycle-state\"=='AVAILABLE'"
  fi
  if [ "$#" = "3" ]; then
    # partial name given, no check for defined tag
    TAG_CONDITION=""
  else
    TAG_CONDITION="&&\"defined-tags\".${TAG_NAMESPACE}.${TAG_KEY}=='${TAG_VALUE}'"
  fi
  NAME=$3
  case "$1" in
    instance)
      RESOURCE_EXPR="compute instance"
      ;;
    dbsystem)
      RESOURCE_EXPR="db system"
      ;;
    autonomousdatabase)
      RESOURCE_EXPR="db autonomous-database"
      ;;
    *)
      echo "### in process_resource : unknown type \”$1\". Continuing."
  esac
  oci ${RESOURCE_EXPR} list \
    --raw-output \
    --output table \
    --compartment-id "${COMPARTMENT_ID}" \
    --query "sort_by(data[?!contains(\"lifecycle-state\",'TERMINAT')
                          ${LIFECYCLE_EXPR} ${TAG_CONDITION}
                          && contains(\"display-name\",'$NAME')],
                     &\"display-name\")[].{\"1 name\":\"display-name\",
                                           \"2 lifecycle-state\":\"lifecycle-state\",
                                           \"3 ocid\":id}"
  TMP_LIST=$(oci ${RESOURCE_EXPR} list --raw-output --compartment-id "${COMPARTMENT_ID}" \
    --query "join(' ',data[?!contains(\"lifecycle-state\",'TERMINAT')
                           ${LIFECYCLE_EXPR}
                           ${TAG_CONDITION} && contains(\"display-name\",'$NAME')].id)")
  OCID_LIST=(${TMP_LIST})
  ERROR_OCIDS=()
  for ocid in "${OCID_LIST[@]}"; do 
    case "$1" in
      instance)
        if [ "${2}" = "stop" ]; then ACTION="softstop"; else ACTION="${2}"; fi
        ACTION_EXPR="compute instance action --action ${ACTION} --instance-id ${ocid}"
        ;;
      dbsystem)
        # must retrieve list of nodes, then operate on nodes
        process_nodes "${2}" "${ocid}" 
        continue
        ;;
      autonomousdatabase)
        ACTION_EXPR="db autonomous-database ${2} --autonomous-database-id ${ocid}"
        ;;
      *)
        echo "### in process_resource : unknown type \”$1\". Continuing."
    esac
    if [ "$1" = "dbsystem" ]; then
      echo -e "###\n### surprising\n###"
      continue
    fi
    echo oci ${OCIOPTIONS} ${ACTION_EXPR}
    if ! OUTPUT=$(oci ${OCIOPTIONS} ${ACTION_EXPR}); then
      ERROR_OCIDS+=(${ocid})
    fi
  done
}

# start or stop resources
# - in compartment
# - with matching defined tag namespace, key and value
# - with matching name
action_all_resources()
{
  debug_print "### in action_all_resources(action=$1, name=$2) #=$#"
  for type in "${TYPE_LIST[@]}"; do
    case "${type}" in
      instance)
        debug_print "processing instances"
        process_resources "instance" $1 $2
        ;;
      dbsystem)
        debug_print "processing db systems"
        process_resources "dbsystem" $1 $2
        ;;
      autonomousdatabase)
        debug_print "processing autonomous databases"
        process_resources "autonomousdatabase" $1 $2
        ;;
      *)
        echo "### resource type ${type} is not supported. Continuing"
    esac
  done
  exit
}

## first argument is start, stop or name argument
## the length of "start" and "stop" is greater than 3
## => test can be made regardless if one or two arguments have been provided
#if [ ${#1} -lt 3 ]; then
#  echo -e "### structured search needs at least 3 characters for comparison.\n### \"$1\" is too short."
#  exit
#fi

# display name matching resources or start/stop all
if [ "$#" = "2" ]; then
  debug_print "### name: $1, action: $2"
  case "$2" in
    start | stop)
      action_all_resources "$2" "$1"
      exit
      ;;
    *)
      usage
      ;;
  esac
fi

# display name matching resources or start/stop all
if [ "$#" = "1" ] || [ "$#" = "0" ]; then
  debug_print "### argument #1: $1"
  case "$1" in
    start | stop)
      action_all_resources "$1"
      exit
      ;;
    *)
      # show resources with matching names
      CONDITION_EXPR=""
      NAME_EXPR="&&contains(\"display-name\",'$1')"
      ;;
  esac
    for type in "${TYPE_LIST[@]}"; do
      case "$type" in
        instance)
          RESOURCE_EXPR="compute instance"
          ;;
        dbsystem)
          RESOURCE_EXPR="db system"
          ;;
        autonomousdatabase)
          RESOURCE_EXPR="db autonomous-database"
          ;;
        *)
          echo "### in process_resource : unknown type \”$1\". Continuing."
      esac
      OUTPUT=$(oci ${OCIOPTIONS} ${RESOURCE_EXPR} list --raw-output --output table --compartment-id "${COMPARTMENT_ID}" \
                   --query "sort_by(data[?!contains(\"lifecycle-state\",'TERMINAT')
                                         ${CONDITION_EXPR} ${NAME_EXPR}],
                                    &\"display-name\")[].{\"   name\":\"display-name\",
                                                          \"  lifecycle-state\":\"lifecycle-state\",
                                                          \" ${TAG_NAMESPACE}.${TAG_KEY}\":\"defined-tags\".${TAG_NAMESPACE}.${TAG_KEY},
                                                          \"ocid\":id}")
      case "$OUTPUT" in
        "Command returned empty list"*)
          echo "No $type resources match \"$1\""
          ;;
        *)
          echo "$OUTPUT"
      esac
    done
  exit
fi
