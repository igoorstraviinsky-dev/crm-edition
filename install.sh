#!/bin/bash
# INSTALADOR STRAVINSKY CRM (Baseado na arquitetura Orion)

amarelo='\e[33m'; branco='\e[97m'; verde='\e[32m'; vermelho='\e[31m'; reset='\e[0m'

clear
echo -e "${amarelo}================================================================${reset}"
echo -e "${branco}        INSTALADOR STRAVINSKY CRM PRO (Straviinsky SETUP)             ${reset}"
echo -e "${amarelo}================================================================${reset}"
echo ""

# 1. Coleta de Variáveis
echo -en "${amarelo}Digite o Domínio (ex: chat.stravinsky.online): ${reset}"; read -r domain
echo -en "${amarelo}Digite o E-mail para SSL: ${reset}"; read -r ssl_email

pg_pass=$(openssl rand -hex 16)
redis_pass=$(openssl rand -hex 16)
secret_key_base=$(openssl rand -hex 64)

# 2. Limpeza profunda de instalações anteriores (Resolve conflito de portas)
echo -e "\n${branco}• [1/4] Limpando resíduos de instalações anteriores...${reset}"
docker swarm leave --force > /dev/null 2>&1
docker stop $(docker ps -aq) > /dev/null 2>&1
docker rm -f $(docker ps -aq) > /dev/null 2>&1
apt-get update -y > /dev/null 2>&1
apt-get install -y curl docker.io docker-compose > /dev/null 2>&1

# 3. Criação do Diretório e Download do Compose
echo -e "${branco}• [2/4] Preparando arquivos de instalação...${reset}"
INSTALL_DIR="/opt/stravinsky-crm"
rm -rf "$INSTALL_DIR" && mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit

GITHUB_URL="https://raw.githubusercontent.com/igoorstraviinsky-dev/crm-edition/main/templates/docker-compose.yaml"
curl -sSLo docker-compose.yaml "$GITHUB_URL"

# 4. Substituição das Variáveis (Cobre qualquer formato que você tenha usado no YAML)
sed -i "s|{{DOMAIN}}|$domain|g; s|\${DOMAIN}|$domain|g" docker-compose.yaml
sed -i "s|{{SSL_EMAIL}}|$ssl_email|g; s|\${SSL_EMAIL}|$ssl_email|g" docker-compose.yaml
sed -i "s|{{PG_PASS}}|$pg_pass|g; s|\${PG_PASS}|$pg_pass|g" docker-compose.yaml
sed -i "s|{{REDIS_PASS}}|$redis_pass|g; s|\${REDIS_PASS}|$redis_pass|g" docker-compose.yaml
sed -i "s|{{SECRET_KEY_BASE}}|$secret_key_base|g; s|\${SECRET_KEY_BASE}|$secret_key_base|g" docker-compose.yaml

# 5. Inicialização no padrão Orion
echo -e "${branco}• [3/4] Iniciando Bancos de Dados...${reset}"
docker-compose up -d postgres redis
echo -e "${amarelo}Aguardando os bancos de dados ficarem prontos (15s)...${reset}"
sleep 15

echo -e "${branco}• [4/4] Subindo aplicação e configurando Chatwoot...${reset}"
docker-compose up -d

echo -e "\n${amarelo}Executando migração do banco de dados (Passo crítico contra Bad Gateway)...${reset}"
# Procura pelo container do Chatwoot e força a criação do banco de dados
CHATWOOT_CONTAINER=$(docker ps -q -f name=chatwoot -f name=api -f name=web | head -n 1)
if [ -n "$CHATWOOT_CONTAINER" ]; then
    docker exec -t "$CHATWOOT_CONTAINER" bundle exec rake db:chatwoot_prepare
fi

echo -e "\n${verde}================================================================${reset}"
echo -e "${branco}       INSTALAÇÃO CONCLUÍDA COM SUCESSO!                        ${reset}"
echo -e "${verde}================================================================${reset}"
echo -e "Acesse seu CRM em: ${amarelo}https://$domain${reset}"
