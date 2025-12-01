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

HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
HOST="${HOSTNAME}-${IP}"

OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null || echo "unknown")
CPU=$(awk '{print $1}' /proc/loadavg)
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM="${RAM_USED}MB/${RAM_TOTAL}MB"
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2}')

# Build JSON data manually
JSON=$(cat <<EOF
{
  "name": "$HOST",
  "inventory": $INVENTORY_ID,
  "enabled": true,
  "variables": "ip: $IP\nserial: $SERIAL\nos: $OS\nkernel: $KERNEL\ncpu: $CPU\nram: $RAM\ndisk: $DISK"
}
EOF
)

echo "Registering host '$HOST' to AWX inventory $INVENTORY_ID..."
curl -s -k \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $AWX_TOKEN" \
  -X POST "$AWX_URL/api/v2/hosts/" \
  -d "$JSON" \
  || echo "NOTE: Host may already exist or AWX returned non-200 code."

echo "Done. Check AWX Inventory: DigiantClients -> Host '$HOST'"
