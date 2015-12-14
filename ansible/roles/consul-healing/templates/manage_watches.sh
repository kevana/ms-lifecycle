#!/usr/bin/env bash

RED="\033[0;31m"
NC="\033[0;0m"

read -r JSON
echo "Consul watch request:"
echo "$JSON"

STATUS_ARRAY=($(echo "$JSON" | jq -r ".[].Status"))
CHECK_ID_ARRAY=($(echo "$JSON" | jq -r ".[].CheckID"))
SERVICE_ID_ARRAY=($(echo "$JSON" | jq -r ".[].ServiceID"))
{% raw %}LENGTH=${#STATUS_ARRAY[*]}{% endraw %}

for (( i=0; i<=$(( $LENGTH -1 )); i++ ))
do
    CHECK_ID=${CHECK_ID_ARRAY[$i]}
    STATUS=${STATUS_ARRAY[$i]}
    SERVICE_ID=${SERVICE_ID_ARRAY[$i]}
    if [[ "$CHECK_ID" == "mem" || "$CHECK_ID" == "disk" ]]; then
        echo -e "${RED}Triggering Jenkins job http://{{ jenkins_ip }}:8080/job/hardware-notification/build${NC}"
        curl -X POST http://{{ jenkins_ip }}:8080/job/hardware-notification/build \
            --data-urlencode json="{\"parameter\": [{\"name\": \"checkId\", \"value\": \"$CHECK_ID\"},{\"name\": \"status\", \"value\": \"$STATUS\"}]}"
    else
        echo -e "${RED}Triggering Jenkins job http://{{ jenkins_ip }}:8080/job/${SERVICE_ID}-redeploy/build${NC}"
        curl -X POST http://{{ jenkins_ip }}:8080/job/${SERVICE_ID}-redeploy/build \
            --data-urlencode json="{\"parameter\": [{\"name\":\"service\", \"value\":\"${SERVICE_ID}\"}]}"
    fi
done
