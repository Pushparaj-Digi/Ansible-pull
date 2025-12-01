#!/bin/bash



AWX_URL="http://192.168.1.11:30080"

AWX_TOKEN="tYijIihFBmNPMPxHYrM1jQWNDXkL9L"

INVENTORY_ID=2



echo "Installing dependencies..."

sudo apt update -y

sudo apt install -y git ansible curl jq



echo "Collecting client details..."

HOSTNAME=$(hostname)

IP=$(hostname -I | awk '{print $1}')

SERIAL=$(cat /proc/cpuinfo | grep Serial | awk '{print $3}')



echo "Registering client $HOSTNAME to AWX..."



curl -X POST "$AWX_URL/api/v2/hosts/" \

  -H "Content-Type: application/json" \

  -H "Authorization: Bearer $AWX_TOKEN" \

  -d "{\"name\":\"$HOSTNAME\",\"description\":\"IP:$IP Serial:$SERIAL\",\"inventory\":$INVENTORY_ID}"



echo "Running ansible-pull..."

ansible-pull -U https://github.com/Pushparaj-Digi/Ansible-pull.git playbooks/register_client.yml

