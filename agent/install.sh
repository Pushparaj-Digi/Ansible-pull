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
SERIAL=$(cat /proc/cpuinfo | grep Serial | awk '{print $3}')
OS_VERSION=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
CPU_LOAD=$(uptime | awk '{print $(NF-2)}' | tr -d ',')
RAM_USAGE=$(free | awk '/Mem/ {printf("%.0f%"), $3/$2 * 100}')
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}')

UNIQUE_NAME="${HOSTNAME}-${IP}"

echo "Registering host '$UNIQUE_NAME' in AWX inventory $INVENTORY_ID..."

curl -s -X POST "$AWX_URL/api/v2/hosts/" \
-H "Authorization: Bearer $AWX_TOKEN" \
-H "Content-Type: application/json" \
-d "{
  \"name\": \"$UNIQUE_NAME\",
  \"inventory\": $INVENTORY_ID,
  \"variables\": \"ip: $IP\nserial: $SERIAL\nos: $OS_VERSION\nkernel: $KERNEL\ncpu: $CPU_LOAD\nram: $RAM_USAGE\ndisk: $DISK_USAGE\"
}" || echo "Host may already exist."

echo "Running local registration playbook..."

ansible-pull -U "https://github.com/Pushparaj-Digi/Ansible-pull.git" playbooks/register_client.yml -i localhost,
