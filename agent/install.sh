#!/bin/bash

set -e

# ====== AWX SETTINGS ======
AWX_URL="http://192.168.1.11:30080"
AWX_TOKEN="tYijIihFBmNPMPxHYrM1jQWNDXkL9L"
INVENTORY_ID=2

echo "Installing dependencies..."
sudo apt update -y
sudo apt install -y ansible git curl jq dmidecode -y

echo "Collecting client details..."

HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
NAME="${HOSTNAME}-${IP}"

# OS details
if [ -f /etc/os-release ]; then
  OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
  OS=$(uname -s)
fi

KERNEL=$(uname -r)

# Serial number
SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null | head -n 1)
if [ -z "$SERIAL" ] || [[ "$SERIAL" == "None" ]] || [[ "$SERIAL" == "Unknown" ]]; then
  SERIAL=$(grep Serial /proc/cpuinfo | awk '{print $3}')
fi

# CPU load
CPU=$(awk '{print $1}' /proc/loadavg)

# RAM used/total
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM="${MEM_USED}MB/${MEM_TOTAL}MB"

# Disk usage example: 12GB/64GB
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2}')

# JSON for AWX variables
variables_json=$(jq -n \
  --arg ip "$IP" \
  --arg serial "$SERIAL" \
  --arg os "$OS" \
  --arg kernel "$KERNEL" \
  --arg cpu "$CPU" \
  --arg ram "$RAM" \
  --arg disk "$DISK" \
  '{ip: $ip, serial: $serial, os: $os, kernel: $kernel, cpu: $cpu, ram: $ram, disk: $disk}')

echo "Registering host '$NAME' to AWX inventory $INVENTORY_ID..."

curl -s -k -H "Authorization: Bearer $AWX_TOKEN" \
 -H "Content-Type: application/json" \
  -X POST "$AWX_URL/api/v2/hosts/" \
  -d "{\"name\":\"$NAME\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":$variables_json}" \
  || echo "Host may already exist"

echo "Done. Check AWX Inventory: DigiantClients -> Host '$NAME'"
