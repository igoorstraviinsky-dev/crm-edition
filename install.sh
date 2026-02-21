#!/bin/bash
# Instalador Stravinsky CRM Pro
amarelo='\e[33m'; branco='\e[97m'; verde='\e[32m'; reset='\e[0m'
clear
echo -e "${amarelo}BEM-VINDO AO INSTALADOR STRAVINSKY CRM${reset}"
echo -en "${amarelo}Domínio (ex: crm.stravinsky.online): ${reset}"; read -r domain
echo -en "${amarelo}E-mail SSL: ${reset}"; read -r ssl_email
pg_pass=$(openssl rand -hex 12); redis_pass=$(openssl rand -hex 12); secret_key_base=$(openssl rand -hex 32)
apt-get update -y && apt-get install -y curl openssl docker.io docker-compose
INSTALL_DIR="/opt/stravinsky-crm"; mkdir -p "$INSTALL_DIR/templates"; cd "$INSTALL_DIR"
GITHUB_URL="https://raw.githubusercontent.com/igoorstraviinsky-dev/crm-edition/main/templates/docker-compose.yaml"
curl -sSLo templates/docker-compose.yaml "$GITHUB_URL"
sed -i "s|{{DOMAIN}}|$domain|g" templates/docker-compose.yaml
sed -i "s|{{PG_PASS}}|$pg_pass|g" templates/docker-compose.yaml
sed -i "s|{{REDIS_PASS}}|$redis_pass|g" templates/docker-compose.yaml
sed -i "s|{{SECRET_KEY_BASE}}|$secret_key_base|g" templates/docker-compose.yaml
docker-compose -f templates/docker-compose.yaml up -d
echo -e "\n${verde}INSTALAÇÃO CONCLUÍDA! Acesse: https://$domain${reset}"
