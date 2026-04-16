#!/bin/bash
set -e

# Nome do container fixo
CONTAINER_NAME="postgres"

# Define o diretório onde o script está localizado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Localização do arquivo .env principal do banco para pegar o admin_principal
MAIN_DB_ENV="$SCRIPT_DIR/../database/.env"

# Verifica se o arquivo .env principal existe e extrai o POSTGRES_USER
if [ -f "$MAIN_DB_ENV" ]; then
    ADMIN_USER=$(grep '^POSTGRES_USER=' "$MAIN_DB_ENV" | cut -d '=' -f2- | tr -d '"' | tr -d "'")
fi

if [ -z "$ADMIN_USER" ]; then
    ADMIN_USER="postgres"
fi

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
echo "      RESET E RESTAURAÇÃO TOTAL DE BANCO DE DADOS POSTGRES      "
echo "================================================================"

# 1. Dados do Banco e do Backup
get_input "Nome do banco de dados (será RESETADO): " DB_NAME
get_input "Caminho completo do arquivo de backup (.sql): " BACKUP_FILE

if [ ! -f "$BACKUP_FILE" ]; then
    echo "ERRO: Arquivo de backup não encontrado em $BACKUP_FILE"
    exit 1
fi

echo "----------------------------------------------------------------"
echo "Limpando conexões e removendo banco '$DB_NAME'..."

# Mata conexões ativas para permitir o DROP
docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -c "
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$DB_NAME'
  AND pid <> pg_backend_pid();" || true

docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;"

echo "Recriando banco de dados vazio..."
docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -c "CREATE DATABASE $DB_NAME;"

# 2. Usuário
while true; do
    echo -n "Deseja (c)riar um novo usuário ou usar um (e)xistente? (c/e): "
    read -r USER_CHOICE < /dev/tty
    case $USER_CHOICE in
        [Cc]* ) 
            get_input "Nome do NOVO usuário: " DB_USER
            get_input "Senha para o novo usuário: " DB_PASS
            docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -c "DROP USER IF EXISTS $DB_USER;"
            docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
            break
            ;;
        [Ee]* ) 
            get_input "Nome do usuário EXISTENTE: " DB_USER
            get_input "Senha do usuário '$DB_USER' (para o .env): " DB_PASS
            break
            ;;
        * ) echo "Resposta inválida." ;;
    esac
done

# 3. Permissões iniciais
echo "Atribuindo permissões..."
docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

# 4. RESTAURAÇÃO DOS DADOS
echo "----------------------------------------------------------------"
echo "Iniciando restauração dos dados de: $BACKUP_FILE"
# O arquivo de backup é injetado via stdin para o psql dentro do container
docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -d "$DB_NAME" < "$BACKUP_FILE"

# 5. Garantia de Permissões Pós-Restauração
echo "Ajustando permissões finais no schema public..."
docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -d "$DB_NAME" -c "GRANT ALL ON SCHEMA public TO $DB_USER;"
docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $DB_USER;"
docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -d "$DB_NAME" -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $DB_USER;"

# 6. Salvar Arquivo .env
ENV_PATH="$SCRIPT_DIR/.db_conn/.env.$DB_NAME"
mkdir -p "$SCRIPT_DIR/.db_conn"
DB_HOST="postgres"
DB_PORT="5432"

cat <<EOF > "$ENV_PATH"
POSTGRES_DB=$DB_NAME
POSTGRES_USER=$DB_USER
POSTGRES_PASSWORD=$DB_PASS
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DATABASE_URL=postgresql://$DB_USER:$DB_PASS@$DB_HOST:$DB_PORT/$DB_NAME
EOF

chmod 600 "$ENV_PATH"

echo "================================================================"
echo "  RESTORE CONCLUÍDO COM SUCESSO!"
echo "  As tabelas e dados foram recriados."
echo "  Configurações: $ENV_PATH"
echo "================================================================"
