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
NEW_NAME="${HOSTNAME}-${IP}"

# OS pretty name
if [ -f /etc/os-release ]; then
  OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
else
  OS=$(uname -s)
fi

KERNEL=$(uname -r)

# Serial number detection
SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null)
if [ -z "$SERIAL" ] || [ "$SERIAL" == "None" ] || [ "$SERIAL" == "Unknown" ]; then
  SERIAL=$(cat /proc/cpuinfo | grep Serial | awk '{print $3}')
fi

# CPU load
CPU=$(awk '{print $1}' /proc/loadavg)

# RAM usage
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
USED_RAM=$(free -m | awk '/Mem:/ {print $3}')
RAM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($USED_RAM/$TOTAL_RAM)*100}")
RAM="${USED_RAM}MB/${TOTAL_RAM}MB (${RAM_PERCENT}%)"

# Disk usage
DISK_PERCENT=$(df -h / | awk 'NR==2 {gsub("%", "", $5); print $5}')
USED_DISK=$(df -h / | awk 'NR==2 {print $3}')
TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
DISK="${USED_DISK}/${TOTAL_DISK} (${DISK_PERCENT}%)"

# Build variable block
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

variables_json=$(printf '%s\n' "$VARS" | jq -Rs .)

echo "Registering host '$NEW_NAME' to AWX inventory $INVENTORY_ID..."

curl -s -k -H "Authorization: Token $AWX_TOKEN" -H "Content-Type: application/json" \
  -X POST "$AWX_URL/api/v2/hosts/" \
  -d "{\"name\":\"$NEW_NAME\",\"inventory\":$INVENTORY_ID,\"enabled
