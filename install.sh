#!/bin/bash
amarelo='\e[33m'; branco='\e[97m'; verde='\e[32m'; reset='\e[0m'

clear
echo -e "${amarelo}BEM-VINDO AO INSTALADOR STRAVINSKY CRM${reset}"
echo "--------------------------------------------------------"
echo -en "${amarelo}Digite o Domínio (ex: crm.stravinsky.online): ${reset}"; read -r domain
echo -en "${amarelo}Digite o E-mail para SSL: ${reset}"; read -r ssl_email

pg_pass=$(openssl rand -hex 12)
redis_pass=$(openssl rand -hex 12)
secret_key_base=$(openssl rand -hex 32)

echo -e "\n${branco}• Preparando Servidor e Docker...${reset}"
apt-get update -y > /dev/null 2>&1
apt-get install -y curl openssl docker.io > /dev/null 2>&1

if docker info | grep -q "Swarm: inactive"; then
    docker swarm init > /dev/null 2>&1
fi

INSTALL_DIR="/opt/stravinsky-crm"
mkdir -p "$INSTALL_DIR/templates"
cd "$INSTALL_DIR" || exit

echo -e "${branco}• Baixando Configurações...${reset}"
GITHUB_URL="https://raw.githubusercontent.com/igoorstraviinsky-dev/crm-edition/main/templates/docker-compose.yaml"
curl -sSLo templates/docker-compose.yaml "$GITHUB_URL"

sed -i "s|\${DOMAIN}|$domain|g" templates/docker-compose.yaml
sed -i "s|\${SSL_EMAIL}|$ssl_email|g" templates/docker-compose.yaml
sed -i "s|\${PG_PASS}|$pg_pass|g" templates/docker-compose.yaml
sed -i "s|\${REDIS_PASS}|$redis_pass|g" templates/docker-compose.yaml
sed -i "s|\${SECRET_KEY_BASE}|$secret_key_base|g" templates/docker-compose.yaml

echo -e "${branco}• Iniciando o CRM no Portainer...${reset}"
docker stack deploy -c templates/docker-compose.yaml stravinsky-crm > /dev/null 2>&1

echo -e "\n${verde}INSTALAÇÃO CONCLUÍDA COM SUCESSO!${reset}"
echo -e "Acesse o painel do seu Portainer para ver a Stack rodando."
echo -e "Acesse seu CRM em: ${amarelo}https://$domain${reset}"
