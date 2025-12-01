#!/bin/bash



set -e



# ===== AWX SETTINGS =====

AWX_URL="http://192.168.1.11:30080"

AWX_TOKEN="PASTE_YOUR_AWX_TOKEN_HERE"

INVENTORY_ID=2



echo "Installing dependencies..."

sudo apt update -y

sudo apt install -y ansible git curl jq dmidecode -y



echo "Collecting client details..."



HOSTNAME=$(hostname)

IP=$(hostname -I | awk '{print $1}')

HOSTNAME_FULL="${HOSTNAME}-${IP}"



if [ -f /etc/os-release ]; then

  OS=$(grep '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')

else

  OS=$(uname -s)

fi



KERNEL=$(uname -r)



SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null | tr -d '"')

if [ -z "$SERIAL" ] || [ "$SERIAL" == "None" ] || [ "$SERIAL" == "Unknown" ]; then

  SERIAL=$(awk -F ': ' '/Serial/ {print $2}' /proc/cpuinfo 2>/dev/null)

fi



CPU=$(awk '{print $1}' /proc/loadavg)



USED_RAM=$(free -m | awk '/Mem:/ {print $3}')

TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')

RAM="${USED_RAM}MB/${TOTAL_RAM}MB"



USED_DISK=$(df -h / | awk 'NR==2 {print $3}')

TOTAL_DISK=$(df -h / | awk 'NR==2 {print $2}')

DISK="${USED_DISK}/${TOTAL_DISK}"



# Create safe JSON

variables_json=$(jq -n \

  --arg ip "$IP" \

  --arg serial "$SERIAL" \

  --arg os "$OS" \

  --arg kernel "$KERNEL" \

  --arg cpu "$CPU" \

  --arg ram "$RAM" \

  --arg disk "$DISK" \

  '{ip: $ip, serial: $serial, os: $os, kernel: $kernel, cpu: $cpu, ram: $ram, disk: $disk}'

)



echo "Registering host '$HOSTNAME_FULL' to AWX inventory $INVENTORY_ID..."

curl -s -k \

  -H "Authorization: Token $AWX_TOKEN" \

  -H "Content-Type: application/json" \

  -X POST "$AWX_URL/api/v2/hosts/" \

  -d "{\"name\":\"$HOSTNAME_FULL\",\"inventory\":$INVENTORY_ID,\"enabled\":true,\"variables\":$variables_json}" \

  || echo "NOTE: Host may already exist; ignoring error."



echo "Done. Check AWX inventory for '$HOSTNAME_FULL'"

