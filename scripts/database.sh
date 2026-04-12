#!/bin/bash
set -e

# Nome do container fixo
CONTAINER_NAME="postgres"

# Define o diretório onde o script está localizado para salvar o arquivo de env
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

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

echo "================================================================"
echo "           CONFIGURAÇÃO DE BANCO DE DADOS POSTGRES              "
echo "================================================================"

# 1. Nome do Banco (Obrigatório)
get_input "Nome do NOVO banco de dados: " DB_NAME

echo "----------------------------------------------------------------"
echo "Criando o banco de dados '$DB_NAME'..."
docker exec -i "$CONTAINER_NAME" psql -U postgres -c "CREATE DATABASE $DB_NAME;"

# 2. Decisão de Usuário
while true; do
    echo -n "Deseja (c)riar um novo usuário ou usar um (e)xistente? (c/e): "
    read -r USER_CHOICE < /dev/tty
    
    case $USER_CHOICE in
        [Cc]* ) 
            get_input "Nome do NOVO usuário: " DB_USER
            get_input "Senha para o novo usuário: " DB_PASS
            
            echo "Criando usuário '$DB_USER'..."
            docker exec -i "$CONTAINER_NAME" psql -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
            break
            ;;
        [Ee]* ) 
            get_input "Nome do usuário EXISTENTE: " DB_USER
            echo "A senha não será alterada, mas informe-a para salvar no arquivo e gerar a URL."
            get_input "Senha do usuário '$DB_USER': " DB_PASS
            break
            ;;
        * ) 
            echo "Resposta inválida. Digite 'c' para criar ou 'e' para existente."
            ;;
    esac
done

# 3. Associação de Permissões
echo "Atribuindo privilégios do banco '$DB_NAME' ao usuário '$DB_USER'..."
docker exec -i "$CONTAINER_NAME" psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
# Garante permissões em schemas (necessário para o Django e outras aplicações)
docker exec -i "$CONTAINER_NAME" psql -U postgres -d "$DB_NAME" -c "GRANT ALL ON SCHEMA public TO $DB_USER;"

echo "----------------------------------------------------------------"
echo "Criando arquivo de ambiente: dbkeys.$DB_NAME"

# 4. Salvar Arquivo com DATABASE_URL
ENV_PATH="$SCRIPT_DIR/dbkeys.$DB_NAME"
DB_HOST="localhost"
DB_PORT="5432"

cat <<EOF > "$ENV_PATH"
POSTGRES_DB=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASS
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT

# URL de conexão formatada
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME
EOF

chmod 600 "$ENV_PATH"

echo "================================================================"
echo "  PROCESSO CONCLUÍDO COM SUCESSO!"
cat "dbkeys.$DB_NAME"
echo "  Configurações salvas em: dbkeys.$DB_NAME"
echo "================================================================"
