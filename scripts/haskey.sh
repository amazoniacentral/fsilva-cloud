#!/bin/bash

# Caminho absoluto para o arquivo de credenciais do Traefik
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CAMINHO_HTPASSWD="$SCRIPT_DIR/../proxy/.htpasswd"

# Verifica se o utilitário htpasswd está instalado
if ! command -v htpasswd &> /dev/null; then
    echo "Instalando apache2-utils..."
    sudo apt-get update && sudo apt-get install -y apache2-utils
fi

# Solicita o nome de usuário de forma interativa
echo -n "Digite o usuário para o Dashboard do Traefik: "
read USER_NAME

# Solicita a senha de forma segura (oculta na digitação)
echo -n "Digite a senha para o Dashboard do Traefik: "
read -s USER_PASS
echo "" # Pula linha após a senha

# Cria o diretório de destino caso ele não exista
mkdir -p "$SCRIPT_DIR/../proxy"

# Gera o hash Bcrypt e salva no arquivo .htpasswd no local correto
htpasswd -bB -c "$CAMINHO_HTPASSWD" "$USER_NAME" "$USER_PASS"

if [ $? -eq 0 ]; then
    echo "------------------------------------------------"
    echo "Sucesso! Credenciais atualizadas."
    echo "Arquivo gerado em: $CAMINHO_HTPASSWD"
    echo "Usuário definido: $USER_NAME"
    echo "------------------------------------------------"
    echo "Para aplicar as mudanças no Traefik, execute:"
    echo "cd $SCRIPT_DIR/../proxy && docker compose up -d"
else
    echo "Erro ao gerar o arquivo de credenciais."
fi
