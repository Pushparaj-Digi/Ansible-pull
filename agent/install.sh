#!/bin/bash



AWX_TOKEN="tYijIihFBmNPMPxHYrM1jQWNDXkL9L"



sudo apt update -y

sudo apt install -y ansible git curl



ansible-pull \

  -U https://github.com/Pushparaj-Digi/Ansible-pull.git \

  playbooks/register_client.yml \

  -e awx_token=$AWX_TOKEN

