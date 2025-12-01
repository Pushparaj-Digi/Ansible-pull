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

NEW_NAME="${HOSTNAME}-${IP}"



# OS pretty name

if [ -f /etc/os-release ]; then

  OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')

else

  OS=$(uname -s)

fi



KERNEL=$(uname -r)



# Serial number

SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null || true)

if [ -z "$SERIAL" ] || [ "$SERIAL" = "None" ] || [ "$SERIAL" = "Unknown" ]; then

  SERIAL=$(grep -m1 'Serial' /proc/cpuinfo 2>/dev/null | awk '{print $3}')

  [ -z "$SERIAL" ] && SERIAL="unknown"

fi



# CPU load (1 min avg)

CPU=$(awk '{print $1}' /proc/loadavg)



# RAM: used/total in GB with percent

TOTAL_RAM_MB=$(free -m | awk '/Mem:/ {print $2}')

USED_RAM_MB=$(free -m | awk '/Mem:/ {print $3}')



if [ -n "$TOTAL_RAM_MB" ] && [ "$TOTAL_RAM_MB" -gt 0 ]; then

  RAM_PERCENT=$(awk "BEGIN {printf \"%.0f\", ($USED_RAM_MB/$TOTAL_RAM_MB)*100}")

  USED_RAM_GB=$(awk "BEGIN {printf \"%.1f\", $USED_RAM_MB/1024}")

  TOTAL_RAM_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_RAM_MB/1024}")

  RAM="${USED_RAM_GB}GB/${TOTAL_RAM_GB}GB (${RAM_PERCENT}%)"

else

  RAM="unknown"

fi



# Disk: used/total with percent

DISK_LINE=$(df -h / | awk 'NR==2')

USED_DISK=$(echo "$DISK_LINE" | awk '{print $3}')

TOTAL_DISK=$(echo "$DISK_LINE" | awk '{print $2}')

DISK_PERCENT=$(echo "$DISK_LINE" | awk '{gsub("%","",$5); print $5}')

DISK="${USED_DISK}/${TOTAL_DISK} (${DISK_PERCENT}%)"



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



variables_json=$(printf '%s\n' "$VARS" | jq -Rs .)



echo "Registering host '$NEW_NAME' in AWX inventory $INVENTORY_ID..."

curl -s -k \

  -H "Authorization: Token $AWX_TOKEN" \

  -H "Content-Type: application/json" \

  -X POST "$AWX_URL/api/v2/hosts/" \

  -d "{\"name\":\"$NEW_NAME\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":$variables_json}" \

  || echo "NOTE: Host may already exist; ignoring error."



echo "Done. Check AWX → Inventory → DigiantClients → Host '$NEW_NAME'."

