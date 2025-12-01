#!/bin/bash
set -e

# ===== AWX SETTINGS =====
AWX_URL="http://100.81.198.28:30080"
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

SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null | head -n1)
if [ -z "$SERIAL" ] || [[ "$SERIAL" == "None" || "$SERIAL" == "Unknown" ]]; then
  SERIAL=$(grep Serial /proc/cpuinfo | awk '{print $3}')
fi

CPU=$(awk '{print $1}' /proc/loadavg)

RAM_USED=$(free -m | awk '/Mem:/ {print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
RAM="${RAM_USED}MB/${RAM_TOTAL}MB"

DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK="${DISK_USED}/${DISK_TOTAL}"

# YAML block to send
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

# Convert to JSON-safe string
ESCAPED_VARS=$(printf "%s" "$VARS" | jq -Rs .)

echo "Registering host '$NAME' to AWX inventory $INVENTORY_ID..."

curl -k -s \
  -H "Authorization: Bearer $AWX_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$AWX_URL/api/v2/hosts/" \
  -d "{\"name\":\"$NAME\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":$ESCAPED_VARS}" \
  || echo "NOTE: Host may already exist."

echo "Done! Check AWX Inventory → DigiantClients → Host '$NAME'"
