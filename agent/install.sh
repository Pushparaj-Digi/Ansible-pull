#!/bin/bash

# ===== CONFIG =====
AWX_URL="http://192.168.1.11:30080"
AWX_TOKEN="tYijIihFBmNPMPxHYrM1jQWNDXkL9L"
INVENTORY_ID="2"

# ===== INSTALL DEPENDENCIES =====
echo "Installing dependencies..."
sudo apt update -y
sudo apt install -y ansible git curl jq dmidecode

# ===== COLLECT DEVICE INFO =====
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
OS=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
RAM=$(free -m | awk 'NR==2{printf "%s", $3/1024}')
DISK=$(df -h / | awk 'NR==2{print $5}')

# SERIAL fallback (VM → Physical RPi)
SERIAL=$(sudo dmidecode -s system-serial-number 2>/dev/null)
if [[ -z "$SERIAL" || "$SERIAL" == "None" || "$SERIAL" == "Unknown" ]]; then
  SERIAL=$(cat /proc/cpuinfo | grep Serial | awk '{print $3}')
fi

echo "Registering host '$HOSTNAME' in AWX inventory $INVENTORY_ID..."

# ===== REGISTER HOST IN AWX =====
curl -k -s -X POST "$AWX_URL/api/v2/hosts/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AWX_TOKEN" \
  -d "{
        \"name\": \"$HOSTNAME\",
        \"inventory\": \"$INVENTORY_ID\",
        \"enabled\": true,
        \"variables\": \"ip: $IP\nserial: $SERIAL\nos: $OS\nkernel: $KERNEL\ncpu: $CPU\nram: $RAM\ndisk: $DISK\"
      }" \
  && echo "Successfully registered" \
  || echo "WARNING: Could not register (maybe already exists)."

echo "Done. Check AWX → Inventory → DigiantClients."
