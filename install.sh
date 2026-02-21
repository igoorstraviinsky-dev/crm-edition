#!/bin/bash

# Acha o caminho da Área de Trabalho do Windows e converte para o formato do WSL
WIN_DESKTOP=$(powershell.exe -Command "[Environment]::GetFolderPath('Desktop')" | tr -d '\r')
WSL_DESKTOP=$(wslpath "$WIN_DESKTOP")

# Cria a pasta de backup
mkdir -p "$WSL_DESKTOP/chatwoot_backup"

echo "Iniciando cópia para a Área de Trabalho do Windows: $WSL_DESKTOP/chatwoot_backup/"

# Sincroniza os arquivos ignorando os diretórios pesados/desnecessários
rsync -a --exclude='node_modules/' \
         --exclude='.bundle/' \
         --exclude='tmp/' \
         --exclude='log/' \
         --exclude='.git/' \
         --exclude='public/packs/' \
         --exclude='public/packs-test/' \
         --exclude='coverage/' \
         --exclude='buildreports/' \
         ~/chatwoot/chatwoot/ "$WSL_DESKTOP/chatwoot_backup/"

echo "--------------------------------------------------------"
echo "✅ Cópia concluída com sucesso na na sua Área de Trabalho (Pasta: chatwoot_backup)!"
echo "--------------------------------------------------------"
