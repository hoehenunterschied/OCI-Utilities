#!/usr/bin/env bash

idiot_counter()
{
   ############################################################
   # force user to type a random string to avoid
   # accidental execution of potentially damaging functions
   ############################################################
   # if tr does not work in the line below, try this:
   #  export STUPID_STRING=$(cat /dev/urandom|LC_ALL=C tr -dc "[:alnum:]"|fold -w 6|head -n 1)
   ############################################################
   export STUPID_STRING="k4JgHrt"
   if [ -e /dev/urandom ];then
     export STUPID_STRING=$(cat /dev/urandom|LC_CTYPE=C tr -dc "[:alnum:]"|fold -w 6|head -n 1)
   fi
   echo -e "#### type \"${STUPID_STRING}\" to approve the above operation ####\n"
   idiot_counter=0
   while true; do
     read line
     case $line in
       ${STUPID_STRING}) break;;
       *)
         idiot_counter=$(($(($idiot_counter+1))%2));
         if [[ $idiot_counter == 0 ]];then
           echo -e "###\n### YOU FAIL !\n###\n### exiting..."; exit;
         fi
         echo "#### type \"${STUPID_STRING}\" to approve the operation above, CTRL-C to abort";
         ;;
     esac
   done
}

INSTANCE_ID=$(curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/id)
AGENT_CONFIG="{\"allPluginsDisabled\": false,\"managementDisabled\": false,\"monitoringDisabled\": false,\"pluginsConfig\": [{\"desiredState\": \"ENABLED\",\"name\": \"OS Management Hub Agent\"}]}"

ARCH_TYPE="$(uname -p)"
ARCH_TYPE="${ARCH_TYPE^^}"
source /etc/os-release
if [[ "$VERSION_ID" == 8* ]]; then
    OS_FAMILY="ORACLE_LINUX_8"
elif [[ "$VERSION_ID" == 9* ]]; then
    OS_FAMILY="ORACLE_LINUX_9"
else
    echo "### version not supported: $VERSION_ID"
    exit
fi

PROFILE_ID="$(oci os-management-hub profile list --all --query "data.items[?\"os-family\" == '${OS_FAMILY}' && \"arch-type\" == '${ARCH_TYPE}' && contains(\"display-name\", '-selfregister')]|[0].id" | tr -d '"')"

printf '\n### registering instance with OS Management Hub\n\n'
printf '### INSTANCE_ID: %s\n' "${INSTANCE_ID}" 
printf '###   ARCH_TYPE: %s\n' "${ARCH_TYPE}" 
printf '###   OS_FAMILY: %s\n' "${OS_FAMILY}" 
printf '###  PROFILE_ID: %s\n\n' "${PROFILE_ID}" 
idiot_counter

# enable OS Management Hub agent
WORKREQUEST_ID=$(oci compute instance update --force --agent-config "${AGENT_CONFIG}" --instance-id "${INSTANCE_ID}" --query "\"opc-work-request-id\"" | tr -d '"')
echo "$WORKREQUEST_ID"
while true; do
  STATE=$(oci work-requests work-request get --work-request-id "${WORKREQUEST_ID}" --query "data.status" | tr -d '"')
  echo $STATE
  case "${STATE}" in
    "SUCCEEDED"|"FAILED"|"CANCELING"|"CANCELED")
      break
      ;;
    *)
      sleep 5
      ;;
  esac
done
curl -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/agentConfig
echo ""
# attach profile to instance
oci os-management-hub managed-instance attach-profile --managed-instance-id "${INSTANCE_ID}" --profile-id "${PROFILE_ID}"
sudo systemctl restart oracle-cloud-agent.service
