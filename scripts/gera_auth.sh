#!/bin/bash
set -e

echo "================================================================"
echo "       GERADOR DE CREDENCIAIS BASIC AUTH (TRAEFIK)              "
echo "================================================================"

get_input() {
    local prompt="$1"
    local var_name="$2"
    local input=""
    
    while [ -z "$input" ]; do
        echo -n "$prompt"
        read -r input < /dev/tty
        if [ -z "$input" ]; then
            echo "ERRO: O campo não pode ser vazio. Tente novamente."
        fi
    done
    eval "$var_name=\"$input\""
}

# 1. Pede o usuário obrigatoriamente
get_input "Digite o usuário (login): " USER_NAME

# 2. Pede a senha obrigatoriamente de forma oculta
while true; do
    echo -n "Digite a senha: "
    read -s USER_PASS < /dev/tty
    echo "" # Pula linha após a senha
    
    if [ -n "$USER_PASS" ]; then
        break
    else
        echo "ERRO: A senha não pode ser vazia. Tente novamente."
    fi
done

echo "----------------------------------------------------------------"
echo "Gerando o hash bcrypt via htpasswd..."

# Instala o utilitário htpasswd caso não esteja presente (sem usar pip)
if ! command -v htpasswd &> /dev/null; then
    apt-get update -qq && apt-get install -y -qq apache2-utils
fi

# Gera o hash no formato user:hash usando bcrypt (-B)
AUTH_RESULT=$(htpasswd -nbB "$USER_NAME" "$USER_PASS")

echo "================================================================"
echo "  CREDENCIAL GERADA COM SUCESSO!"
echo "================================================================"
echo "Copie a linha abaixo e cole no seu arquivo .env:"
echo ""
echo "$AUTH_RESULT"
echo ""
echo "================================================================"
