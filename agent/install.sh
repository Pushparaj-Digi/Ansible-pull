#!/bin/bash
set -e

# ===== AWX SETTINGS =====
AWX_URL="http://192.168.1.11:30080"
AWX_TOKEN="VgC7mlJ09cSqPDIHGg8jIf6v4Y1oRC"
INVENTORY_ID=2

echo "Collecting client details..."

HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
NAME="${HOSTNAME}-${IP}"

OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
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

# Build YAML-style string with quotes
VARIABLES=$(printf "ip: \"%s\"\nserial: \"%s\"\nos: \"%s\"\nkernel: \"%s\"\ncpu: \"%s\"\nram: \"%s\"\ndisk: \"%s\"" \
  "$IP" "$SERIAL" "$OS" "$KERNEL" "$CPU" "$RAM" "$DISK" | sed ':a;N;$!ba;s/\n/\\n/g')

echo "Registering host '$NAME' to AWX inventory $INVENTORY_ID..."

curl -k -s \
  -H "Authorization: Bearer $AWX_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST "$AWX_URL/api/v2/hosts/" \
  -d "{\"name\":\"$NAME\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":\"$VARIABLES\"}" \
  || echo "NOTE: Host may already exist; ignoring error."

echo "Done! Check AWX Inventory → DigiantClients → Host '$NAME'"
