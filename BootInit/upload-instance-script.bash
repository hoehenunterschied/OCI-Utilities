#!/usr/bin/env bash

BUCKET_NAME="InstanceScripts"
NAMESPACE="$(oci os ns get --query "data" | tr -d '"')"

for file in "$@"; do
    if [ -e "$file" ]; then
        echo "Processing file: $file"
        oci os object put -bn "${BUCKET_NAME}" \
                          -ns "${NAMESPACE}" \
                          --file "${file}"
    else
        echo "File not found: $file"
    fi
done

