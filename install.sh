
#!/bin/bash

# Cores do Setup do Stravinsky
amarelo='\e[33m'
branco='\e[97m'
verde='\e[32m'
vermelho='\e[31m'
reset='\e[0m'

clear
echo -e "${amarelo}"
cat << "EOF"
  ____  _                  _           _          ____ ____  __  __ 
 / ___|| |_ _ __ __ ___   _(_)_ __  ___| | ___   / ___|  _ \|  \/  |
 \___ \| __| '__/ _` \ \ / / | '_ \/ __| |/ / | | |   | |_) | |\/| |
  ___) | |_| | | (_| |\ V /| | | | \__ \   <| |_| |   |  _ <| |  | |
 |____/ \__|_|  \__,_| \_/ |_|_| |_|___/_|\_\\___/ \____|_| \_\_|  |_|
EOF
echo -e "${reset}"
echo -e "${branco}================================================================${reset}"
echo -e "${amarelo}          BEM-VINDO AO INSTALADOR STRAVINSKY CRM                ${reset}"
echo -e "${branco}================================================================${reset}"
echo ""

# Verifica se é root
if [ "$EUID" -ne 0 ]; then
  echo -e "${vermelho}[ERRO] Por favor, execute este script como root (sudo bash install.sh)${reset}"
  exit 1
fi

echo -e "${branco}Selecione a ferramenta que deseja instalar:${reset}"
echo ""
echo -e "  ${amarelo}[1]${reset} Instalar Stravinsky CRM Pro (Chatwoot)"
echo -e "  ${amarelo}[0]${reset} Sair do Instalador"
echo ""
echo -en "${branco}Opção: ${reset}"
read -r opcao

if [ "$opcao" != "1" ]; then
    echo -e "${amarelo}Saindo...${reset}"
    exit 0
fi

clear
echo -e "${amarelo}Iniciando a configuração do Stravinsky CRM Pro...${reset}"
echo "--------------------------------------------------------"

while true; do
    echo -e "${branco}Passo${amarelo} 1/4${reset}"
    echo -en "${amarelo}Digite o Domínio para o CRM (ex: crm.stravinsky.online): ${reset}"
    read -r domain
    echo ""

    echo -e "${branco}Passo${amarelo} 2/4${reset}"
    echo -en "${amarelo}Digite o E-mail para registrar o Certificado SSL (Let's Encrypt): ${reset}"
    read -r ssl_email
    echo ""

    echo -e "${branco}Passo${amarelo} 3/4${reset}"
    echo -en "${amarelo}Defina a senha do Postgres (deixe em branco para gerar aleatória): ${reset}"
    read -r pg_pass
    if [ -z "$pg_pass" ]; then
        pg_pass=$(openssl rand -hex 12)
        echo -e "${verde}  -> Senha gerada automaticamente: ${branco}$pg_pass${reset}"
    fi
    echo ""

    echo -e "${branco}Passo${amarelo} 4/4${reset}"
    echo -en "${amarelo}Defina a senha do Redis (deixe em branco para gerar aleatória): ${reset}"
    read -r redis_pass
    if [ -z "$redis_pass" ]; then
        redis_pass=$(openssl rand -hex 12)
        echo -e "${verde}  -> Senha gerada automaticamente: ${branco}$redis_pass${reset}"
    fi
    echo ""

    secret_key_base=$(openssl rand -hex 32)
    
    echo -e "${branco}================================================================${reset}"
    echo -e "${amarelo}Confirme as informações inseridas:${reset}"
    echo -e "${branco}Domínio        :${reset} $domain"
    echo -e "${branco}E-mail SSL     :${reset} $ssl_email"
    echo -e "${branco}Senha Postgres :${reset} $pg_pass"
    echo -e "${branco}Senha Redis    :${reset} $redis_pass"
    echo -e "${branco}================================================================${reset}"
    echo -en "${amarelo}As respostas estão corretas? (Y/N): ${reset}"
    read -r confirmacao

    if [[ "$confirmacao" =~ ^[Yy]$ ]]; then
        break
    else
        clear
        echo -e "${vermelho}Vamos tentar novamente. Por favor, reveja os dados...${reset}"
        echo ""
    fi
done

echo ""
echo -e "${branco}• PREPARANDO DEPENDÊNCIAS ${amarelo}[1/3]${reset}"
apt-get update -y > /dev/null 2>&1
apt-get install -y curl openssl > /dev/null 2>&1

if ! command -v docker &> /dev/null; then
    echo -e "${verde}  -> Instalando Docker base...${reset}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh > /dev/null 2>&1
    rm get-docker.sh
fi

if docker info | grep -q "Swarm: inactive"; then
    echo -e "${verde}  -> Inicializando Docker Swarm (Para integração com Portainer)...${reset}"
    docker swarm init > /dev/null 2>&1
fi

echo ""
echo -e "${branco}• CONFIGURANDO ARQUIVOS DA STACK ${amarelo}[2/3]${reset}"
INSTALL_DIR="/opt/stravinsky-crm"
mkdir -p "$INSTALL_DIR"

if [ -d "./templates" ] && [ -f "./templates/docker-compose.yaml" ]; then
    echo -e "${verde}  -> Copiando docker-compose.yaml local...${reset}"
    cp ./templates/docker-compose.yaml "$INSTALL_DIR/"
else
    echo -e "${amarelo}  -> Baixando arquivo docker-compose.yaml do repositório...${reset}"
    # Substitua a URL abaixo pela URL RAW do seu arquivo docker-compose.yaml no GitHub
    GITHUB_REPO_RAW_URL="https://raw.githubusercontent.com/igoorstraviinsky/crm-edition/main/installer/templates/docker-compose.yaml"
    curl -sSLo "$INSTALL_DIR/docker-compose.yaml" "$GITHUB_REPO_RAW_URL"
    
    if [ ! -f "$INSTALL_DIR/docker-compose.yaml" ]; then
        echo -e "${vermelho}[ERRO] Falha ao baixar o docker-compose.yaml do repositório.${reset}"
        exit 1
    fi
fi

# Injetando as váriaveis no arquivo yaml do portainer
sed -i "s/\${DOMAIN}/$domain/g" "$INSTALL_DIR/docker-compose.yaml"
sed -i "s/\${SSL_EMAIL}/$ssl_email/g" "$INSTALL_DIR/docker-compose.yaml"
sed -i "s/\${PG_PASS}/$pg_pass/g" "$INSTALL_DIR/docker-compose.yaml"
sed -i "s/\${REDIS_PASS}/$redis_pass/g" "$INSTALL_DIR/docker-compose.yaml"
sed -i "s/\${SECRET_KEY_BASE}/$secret_key_base/g" "$INSTALL_DIR/docker-compose.yaml"

echo ""
echo -e "${branco}• INICIANDO APLICAÇÃO NO PORTAINER ${amarelo}[3/3]${reset}"
cd "$INSTALL_DIR" || exit
docker stack deploy -c docker-compose.yaml stravinsky-crm > /dev/null 2>&1

echo ""
echo -e "${verde}================================================================${reset}"
echo -e "${branco}       INSTALAÇÃO CONCLUÍDA COM SUCESSO!                        ${reset}"
echo -e "${verde}================================================================${reset}"
echo -e "${branco}Guarde seus dados de acesso:${reset}"
echo -e " \n-> Domínio de Acesso:  ${amarelo}https://$domain${reset}"
echo -e "-> Senha do Postgres:  ${amarelo}$pg_pass${reset}"
echo -e "-> Senha do Redis:     ${amarelo}$redis_pass${reset}"
echo ""
echo -e "${verde}A stack está agora ativa no painel visual do seu Portainer!${reset}"
