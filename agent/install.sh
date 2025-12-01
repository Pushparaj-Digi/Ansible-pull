#!/bin/bash
set -e

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

OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"' || uname -s)
KERNEL=$(uname -r)

SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null)
if [[ -z "$SERIAL" || "$SERIAL" == "None" || "$SERIAL" == "Unknown" ]]; then
  SERIAL=$(grep Serial /proc/cpuinfo | awk '{print $3}')
fi
[ -z "$SERIAL" ] && SERIAL="unknown"

TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
USED_RAM=$(free -m | awk '/Mem:/ {print $3}')
RAM="${USED_RAM}MB/${TOTAL_RAM}MB"

DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK="${DISK_USED}/${DISK_TOTAL}"
CPU=$(awk '{print $1}' /proc/loadavg)

VARS=$(cat <<EOF
ip: "$IP"
serial: "$SERIAL"
os: "$OS"
kernel: "$KERNEL"
cpu: "$CPU"
ram: "$RAM"
disk: "$DISK"
EOF
)

# Escape double-quotes and newlines for AWX JSON payload
variables_string=$(printf "%s" "$VARS" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

echo "Registering host '$NAME' to AWX inventory $INVENTORY_ID..."

curl -s -k \
  -H "Authorization: Bearer $AWX_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$AWX_URL/api/v2/hosts/" \
  -d "{\"name\":\"$NAME\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":\"$variables_string\"}" \
  || echo "NOTE: Host may already exist; ignoring error."

echo "Done! Check AWX Inventory → DigiantClients → Host $NAME"
