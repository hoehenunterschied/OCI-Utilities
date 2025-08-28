#!/usr/bin/env bash

tempfile=$(mktemp)
echo "Temporary file created: $tempfile"

curl -s -H "Authorization: Bearer Oracle" http://169.254.169.254/opc/v2/instance/regionInfo > "${tempfile}"
export REGION=$(cat "${tempfile}" | jq -r ".regionIdentifier")
export DOMAIN=$(cat "${tempfile}" | jq -r ".realmDomainComponent")
curl -s https://osmh."${REGION}".oci."${DOMAIN}" &>/dev/null ; [ $? == 0 ] && echo "Success" || echo "Failure"
rm "${tempfile}"
