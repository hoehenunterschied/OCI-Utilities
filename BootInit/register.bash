#!/usr/bin/env bash

INSTANCE_NAME="quicktest"
INSTANCE_ID="ocid1.instance.oc1.eu-frankfurt-1.antheljsttkvkkicy7j7cvshbhpuxiz64it2k4itrula7golcdg5u27wqxga"
PROFILE_ID="ocid1.osmhprofile.oc1.eu-frankfurt-1.amaaaaaattkvkkiadxha3nmuf3uypfll66l57t6peyjjkk3vmrudvjzgsqva"
AGENT_CONFIG="{\"allPluginsDisabled\": false,\"managementDisabled\": false,\"monitoringDisabled\": false,\"pluginsConfig\": [{\"desiredState\": \"ENABLED\",\"name\": \"OS Management Hub Agent\"}]}"

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
ssh "${INSTANCE_NAME}" curl -H \"Authorization: Bearer Oracle\" -L http://169.254.169.254/opc/v2/instance/agentConfig\; echo \"\"
echo ""
exit
oci os-management-hub managed-instance attach-profile --managed-instance-id "${INSTANCE_ID}" --profile-id "${PROFILE_ID}"
ssh "${INSTANCE_NAME}" sudo systemctl restart oracle-cloud-agent.service
