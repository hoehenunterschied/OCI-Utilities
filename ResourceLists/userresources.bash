#!/bin/bash
TAG_NAMESPACE="<fill in tag namespace>"
TAG_KEY="<fill in tag key>"
USER="john.doe@acme.com"

if [ "$#" -eq 1 ]; then
  USER="$1"
fi
TAG_VALUE="oracleidentitycloudservice/${USER}"

oci search resource structured-search --limit 5000 \
  --query-text "query all resources 
                  where (
                       definedTags.namespace='${TAG_NAMESPACE}'
                    && definedTags.key='${TAG_KEY}'
                    && definedTags.value='${TAG_VALUE}'
                    && lifecycleState!='TERMINATED'
                  )" \
  --query "sort_by(data.items[],&\"resource-type\")
           | [].{type:\"resource-type\",
                 ocid:identifier,
                 state:\"lifecycle-state\",
                 name:\"display-name\"}" \
  --output table
