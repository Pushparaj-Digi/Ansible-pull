#!/bin/bash

set -e

# ====== AWX SETTINGS ======
AWX_URL="http://192.168.1.11:30080"
AWX_TOKEN="PASTE_YOUR_AWX_TOKEN_HERE"
INVENTORY_ID=2

echo "Installing dependencies..."
sudo apt update -y
sudo apt install -y ansible git curl jq dmidecode -y

echo "Collecting client details..."

HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')

# OS pretty name
if [ -f /etc/os-release ]; then
  OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
  OS=$(uname -s)
fi

KERNEL=$(uname -r)

# Serial number (requires dmidecode + sudo)
SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null)
if [ -z "$SERIAL" ] || [ "$SERIAL" == "None" ] || [ "$SERIAL" == "Unknown" ]; then
  SERIAL=$(cat /proc/cpuinfo | grep Serial | awk '{print $3}')
fi

# CPU load (1-minute load avg)
CPU=$(awk '{print $1}' /proc/loadavg)

# RAM usage in %
RAM=$(free -m | awk '/Mem:/ {printf "%.0f", $3/$2*100}')

# Root disk usage in %
DISK=$(df -h / | awk 'NR==2 {gsub("%","",$5); print $5}')

# Build YAML variables string
VARS=$(cat <<EOF
ip: $IP
serial: $SERIAL
os: $OS
kernel: $KERNEL
cpu: $CPU
ram: $RAM
disk: $DISK
EOF
)

# Convert YAML string to JSON string for AWX
variables_json=$(printf '%s\n' "$VARS" | jq -Rs .)

echo "Registering host '$HOSTNAME' in AWX inventory $INVENTORY_ID..."
curl -s -k -H "Authorization: Token $AWX_TOKEN" -H "Content-Type: application/json" \
  -X POST "$AWX_URL/api/v2/hosts/" \
  -d "{\"name\":\"$HOSTNAME\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":$variables_json}" \
  || echo "NOTE: Host may already exist; ignoring error."

echo "Done. Check AWX → Inventory → DigiantClients → Host '$HOSTNAME'."
