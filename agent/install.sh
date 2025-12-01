#!/bin/bash

AWX_URL="http://192.168.1.11:30080"
AWX_TOKEN="tYijIihFBmNPMPxHYrM1jQWNDXkL9L"
INVENTORY_ID=2

echo "Installing dependencies..."
sudo apt-get update -y
sudo apt-get install -y ansible git curl jq

echo "Collecting client details..."
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')

echo "Registering host '$HOSTNAME' in AWX inventory $INVENTORY_ID..."

curl -s -X POST "$AWX_URL/api/v2/hosts/" \
-H "Authorization: Bearer $AWX_TOKEN" \
-H "Content-Type: application/json" \
-d "{\"name\":\"$HOSTNAME\",\"inventory\":$INVENTORY_ID,\"variables\":\"ip: $IP\"}"

echo "Running local registration playbook..."
ansible-pull -U "https://github.com/Pushparaj-Digi/Ansible-pull.git" playbooks/register_client.yml -i localhost,
