#!/bin/bash
set -e

# ===== AWX SETTINGS =====
AWX_URL="http://192.168.1.11:30080"
AWX_TOKEN="VgC7mlJ09cSqPDIHGg8jIf6v4Y1oRC"
INVENTORY_ID=2

echo "Installing dependencies..."
sudo apt update -y
sudo apt install -y ansible git curl jq dmidecode -y

echo "Collecting client details..."

HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
NAME="${HOSTNAME}-${IP}"

OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"' || uname -s)
KERNEL=$(uname -r)

SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null)
if [ -z "$SERIAL" ] || [ "$SERIAL" == "None" ] || [ "$SERIAL" == "Unknown" ]; then
  SERIAL=$(grep Serial /proc/cpuinfo | awk '{print $3}')
fi

CPU=$(awk '{print $1}' /proc/loadavg)

USED_RAM=$(free -m | awk '/Mem:/ {print $3}')
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
RAM="${USED_RAM}MB/${TOTAL_RAM}MB"

USED_DISK=$(df -h / | awk 'NR==2 {print $3}')
TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')
DISK="${USED_DISK}/${TOTAL_DISK}"

# Build YAML variables (as plain string)
VARIABLES="ip: $IP\nserial: $SERIAL\nos: $OS\nkernel: $KERNEL\ncpu: $CPU\nram: $RAM\ndisk: $DISK"

echo "Registering host '$NAME' to AWX inventory $INVENTORY_ID..."

curl -k -s -H "Authorization: Bearer $AWX_TOKEN" \
     -H "Content-Type: application/json" \
     -X POST "$AWX_URL/api/v2/hosts/" \
     -d "{\"name\":\"$NAME\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":\"$VARIABLES\"}" \
     || echo "NOTE: Host may already exist; ignoring error."

echo "Done! Check AWX Inventory → DigiantClients → Host '$NAME'"
