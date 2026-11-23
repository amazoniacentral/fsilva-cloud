#!/bin/bash
set -e

echo "================================================================"
echo "       GERADOR DE CREDENCIAIS BASIC AUTH (TRAEFIK)              "
echo "================================================================"

# Função para garantir que a entrada não seja vazia
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
echo "Gerando o hash bcrypt via Python..."

# Verifica se o python3 está instalado
if ! command -v python3 &> /dev/null; then
    echo "ERRO: python3 não está instalado."
    exit 1
fi

# Garante que a biblioteca bcrypt está disponível no ambiente python
if ! python3 -c "import bcrypt" &> /dev/null; then
    echo "Biblioteca 'bcrypt' não encontrada no Python. Instalando via pip..."
    pip install bcrypt --quiet
fi

# Executa o comando python para gerar o hash e capturar a string formatada
AUTH_RESULT=$(python3 -c "
import bcrypt
user = '$USER_NAME'
password = b'$USER_PASS'
hashed = bcrypt.hashpw(password, bcrypt.gensalt()).decode()
print(f'{user}:{hashed}')
")

echo "================================================================"
echo "  CREDENCIAL GERADA COM SUCESSO!"
echo "================================================================"
echo "Copie a linha abaixo e cole no seu arquivo .env:"
echo ""
echo "$AUTH_RESULT"
echo ""
echo "================================================================"
