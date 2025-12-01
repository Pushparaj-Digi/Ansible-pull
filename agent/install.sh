#!/bin/bash



AWX_URL="http://192.168.1.11:30080/api/v2/hosts/"

AWX_TOKEN="lXnGYSOrOYNqrKQTZ3P2rZRDQdVRbs"

INVENTORY_ID="2"



HOSTNAME=$(hostname)

IP=$(hostname -I | awk '{print $1}')

SERIAL=$(cat /proc/cpuinfo | grep Serial | awk '{print $3}')



echo "Registering client $HOSTNAME to AWX..."



curl -k -s -X POST "$AWX_URL" \

  -H "Content-Type: application/json" \

  -H "Authorization: Bearer $AWX_TOKEN" \

  -d "{

      \"name\": \"$HOSTNAME\",

      \"description\": \"IP:$IP Serial:$SERIAL\",

      \"inventory\": \"$INVENTORY_ID\"

  }"



echo "Running registration playbook..."

ansible-pull \

  -U https://github.com/Pushparaj-Digi/Ansible-pull.git \

  playbooks/register_client.yml

