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



# OS pretty name

if [ -f /etc/os-release ]; then

  OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')

else

  OS=$(uname -s)

fi



KERNEL=$(uname -r)



# Serial number

SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null || true)

if [ -z "$SERIAL" ] || [ "$SERIAL" = "None" ] || [ "$SERIAL" = "Unknown" ]; then

  SERIAL=$(grep -m1 Serial /proc/cpuinfo 2>/dev/null | awk '{print $3}')

fi

[ -z "$SERIAL" ] && SERIAL="unknown"



# CPU load (1-minute)

CPU=$(awk '{print $1}' /proc/loadavg)



# RAM used/total in MB

read -r _ TOTAL_RAM USED_RAM _ < <(free -m | awk '/Mem:/ {print $1, $2, $3, $4}')

RAM="${USED_RAM}MB/${TOTAL_RAM}MB"



# Root disk used/total in human-readable form (e.g. 3.1G/16G)

read -r SIZE USED _ USEP _ < <(df -h / | awk 'NR==2 {print $2, $3, $4, $5, $6}')

DISK="${USED}/${SIZE} (${USEP})"



# Build plain YAML string (this *previous style* was working for you)

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



# Wrap that YAML into a JSON string for the AWX API

variables_json=$(printf '%s\n' "$VARS" | jq -Rs .)



echo "Registering host '$NAME' in AWX inventory $INVENTORY_ID..."



curl -s -k \

  -H "Authorization: Bearer $AWX_TOKEN" \

  -H "Content-Type: application/json" \

  -X POST "$AWX_URL/api/v2/hosts/" \

  -d "{\"name\":\"$NAME\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":$variables_json}" \

  || echo "NOTE: Host may already exist; ignoring error."



echo "Done! Check AWX Inventory → DigiantClients → Host '$NAME'."

