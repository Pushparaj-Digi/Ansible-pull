#!/bin/bash



### CONFIG ###

AWX_URL="http://192.168.1.11:30080"

AWX_TOKEN="tYijIihFBmNPMPxHYrM1jQWNDXkL9L"

INVENTORY_ID="2"

REGION="default"



echo "Installing dependencies..."

sudo apt-get update -y

sudo apt-get install -y ansible git curl jq



echo "Collecting client details..."

HOSTNAME=$(hostname)

IP=$(hostname -I | awk '{print $1}')

SERIAL=$(grep Serial /proc/cpuinfo | awk '{print $3}')



echo "Registering client $HOSTNAME to AWX..."



curl -s -X POST "$AWX_URL/api/v2/hosts/" \

    -H "Authorization: Bearer $AWX_TOKEN" \

    -H "Content-Type: application/json" \

    -d "{\"name\":\"$HOSTNAME\",\"inventory\":$INVENTORY_ID,\"description\":\"Auto added client\",\"variables\":\"ip: $IP\nserial: $SERIAL\nregion: $REGION\"}"



echo "Running registration playbook with ansible-pull..."



ansible-pull \

  -U https://github.com/Pushparaj-Digi/Ansible-pull.git \

  playbooks/register_client.yml \

  --extra-vars "awx_token=$AWX_TOKEN awx_url=$AWX_URL inventory_id=$INVENTORY_ID hostname=$HOSTNAME"

