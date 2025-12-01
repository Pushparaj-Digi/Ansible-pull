#!/bin/bash
set -e

# ===== AWX SETTINGS =====
AWX_URL="http://192.168.1.11:30080"
AWX_TOKEN="tYijIihFBmNPMPxHYrM1jQWNDXkL9L"
INVENTORY_ID=2

echo "Installing dependencies..."
sudo apt update -y
sudo apt install -y ansible git curl jq dmidecode -y

echo "Collecting client details..."

HOST=$(hostname)
IP=$(hostname -I | awk '{print $1}')
HOSTNAME="${HOST}-${IP}"

# OS name
OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')

# Kernel
KERNEL=$(uname -r)

# Serial number
SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null)
if [[ -z "$SERIAL" || "$SERIAL" == "None" || "$SERIAL" == "Unknown" ]]; then
  SERIAL=$(grep Serial /proc/cpuinfo | awk '{print $3}')
fi

# CPU load
CPU=$(awk '{print $1}' /proc/loadavg)

# RAM format: used/total in MB
USED_RAM=$(free -m | awk '/Mem:/ {print $3}')
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
RAM="${USED_RAM}MB/${TOTAL_RAM}MB"

# Disk format: used/total
USED_DISK=$(df -h / | awk 'NR==2 {print $3}')
TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
DISK="${USED_DISK}/${TOTAL_DISK}"

# Create JSON payload
JSON=$(jq -n \
  --arg name "$HOSTNAME" \
  --arg ip "$IP" \
  --arg serial "$SERIAL" \
  --arg os "$OS" \
  --arg kernel "$KERNEL" \
  --arg cpu "$CPU" \
  --arg ram "$RAM" \
  --arg disk "$DISK" \
  --argjson inventory "$INVENTORY_ID" \
  '{name:$name, inventory:$inventory, enabled:true, variables:{ip:$ip, serial:$serial, os:$os, kernel:$kernel, cpu:$cpu, ram:$ram, disk:$disk}}'
)

echo "Registering host '$HOSTNAME' to AWX inventory $INVENTORY_ID..."
curl -s -k \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $AWX_TOKEN" \
  -X POST "$AWX_URL/api/v2/hosts/" \
  -d "$JSON" \
  || echo "NOTE: Host may already exist."

echo "Registration complete."
echo "Check AWX → Inventory → DigiantClients → Host '$HOSTNAME'"
