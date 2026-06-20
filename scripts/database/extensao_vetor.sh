#!/bin/bash
set -e

# Define o diretório onde o script está localizado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Localização do arquivo .env principal do banco para pegar o admin_principal
MAIN_DB_ENV="$SCRIPT_DIR/../../database/.env"

# Verifica se o arquivo .env principal existe e extrai o POSTGRES_USER
if [ -f "$MAIN_DB_ENV" ]; then
    # Extrai o valor de POSTGRES_USER removendo possíveis espaços e aspas
    ADMIN_USER=$(grep '^POSTGRES_USER=' "$MAIN_DB_ENV" | cut -d '=' -f2- | tr -d '"' | tr -d "'")
fi

# Se não encontrar no .env ou o arquivo não existir, assume 'postgres' como fallback
if [ -z "$ADMIN_USER" ]; then
    ADMIN_USER="postgres"
fi

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
echo "           SELEÇÃO DE CONTAINER POSTGRES                        "
echo "================================================================"

# Filtra apenas containers que possuem 'postgres' no nome ou na imagem
mapfile -t CONTAINERS < <(docker ps --format "{{.Names}} ({{.Image}})" | grep -i "postgres")

if [ ${#CONTAINERS[@]} -eq 0 ]; then
    echo "ERRO: Nenhum container Postgres em execução encontrado."
    exit 1
fi

echo "Selecione o container Postgres desejado:"
for i in "${!CONTAINERS[@]}"; do
    echo "  $((i+1))) ${CONTAINERS[$i]}"
done

while true; do
    echo -n "Digite o número correspondente: "
    read -r CHOICE < /dev/tty
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#CONTAINERS[@]}" ]; then
        # Extrai apenas o nome do container (antes do primeiro espaço)
        CONTAINER_NAME=$(echo "${CONTAINERS[$((CHOICE-1))]}" | awk '{print $1}')
        break
    else
        echo "Opção inválida."
    fi
done

echo "Container selecionado: $CONTAINER_NAME"
echo "----------------------------------------------------------------"

echo "================================================================"
echo "           SELEÇÃO DE BANCO DE DADOS                            "
echo "================================================================"

# Executa comando interno para extrair as bases reais, pulando as padrões do sistema Postgres
mapfile -t DATABASES < <(docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -d postgres -t -A -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname NOT IN ('postgres', 'rdsadmin');")

if [ ${#DATABASES[@]} -eq 0 ]; then
    echo "ERRO: Nenhum banco de dados personalizado encontrado nesse container."
    exit 1
fi

echo "Selecione o banco de dados para ativar o pgvector:"
for i in "${!DATABASES[@]}"; do
    echo "  $((i+1))) ${DATABASES[$i]}"
done

while true; do
    echo -n "Digite o número correspondente: "
    read -r DB_CHOICE < /dev/tty
    if [[ "$DB_CHOICE" =~ ^[0-9]+$ ]] && [ "$DB_CHOICE" -ge 1 ] && [ "$DB_CHOICE" -le "${#DATABASES[@]}" ]; then
        DB_NAME="${DATABASES[$((DB_CHOICE-1))]}"
        break
    else
        echo "Opção inválida."
    fi
done

echo "Banco de dados selecionado: $DB_NAME"
echo "----------------------------------------------------------------"

echo "================================================================"
echo "           ATIVAÇÃO DO EXTENSION PGVECTOR                       "
echo "           (Usando Admin: $ADMIN_USER)                          "
echo "================================================================"

echo "Verificando e ativando a extensão 'vector' no banco '$DB_NAME'..."

# Executa o comando de criação da extensão usando os privilégios do usuário administrador logado diretamente no banco alvo
docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;"

echo "----------------------------------------------------------------"
echo "================================================================"
echo "  PROCESSO CONCLUÍDO COM SUCESSO!"
echo "  A extensão 'vector' foi habilitada com sucesso no banco '$DB_NAME'."
echo "================================================================"
