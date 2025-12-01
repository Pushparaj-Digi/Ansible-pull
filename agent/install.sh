#!/bin/bash

# ====== CONFIG ======
AWX_TOKEN="tYijIihFBmNPMPxHYrM1jQWNDXkL9L"
AWX_URL="http://192.168.1.11:30080"
INVENTORY_ID="2"
REGION="default"

echo "Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y ansible git curl jq

echo "Collecting client details..."
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
SERIAL=$(cat /proc/cpuinfo | grep Serial | awk '{print $3}')

echo "Registering client $HOSTNAME to AWX..."

curl -s -X POST "$AWX_URL/api/v2/hosts/" -H "Authorization: Bearer $AWX_TOKEN" -H "Content-Type: application/json" \
-d "{\"name\":\"$HOSTNAME\",\"description\":\"Auto registered client\",\"inventory\":$INVENTORY_ID,\"variables\":\"ip: $IP\nserial: $SERIAL\nregion: $REGION\"}"

echo "Running registration playbook..."
ansible-pull -U https://github.com/Pushparaj-Digi/Ansible-pull.git playbooks/register_client.yml
