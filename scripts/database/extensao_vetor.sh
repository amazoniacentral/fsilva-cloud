#!/bin/bash
set -e

# Define o diretório onde o script está localizado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
MAIN_DB_ENV="$SCRIPT_DIR/../../database/.env"

# Extração de ADMIN_USER (mantida igual)
if [ -f "$MAIN_DB_ENV" ]; then
    ADMIN_USER=$(grep '^POSTGRES_USER=' "$MAIN_DB_ENV" | cut -d '=' -f2- | tr -d '"' | tr -d "'")
fi
[ -z "$ADMIN_USER" ] && ADMIN_USER="postgres"

# --- BLOCO NOVO: VERIFICAÇÃO DE ARGUMENTOS ---
CONTAINER_NAME="${1:-}"
DB_NAME="${2:-}"

# Se forneceu container e banco, valida se existem antes de prosseguir
if [ -n "$CONTAINER_NAME" ] && [ -n "$DB_NAME" ]; then
    # Verifica container
    if ! docker ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "ERRO: Container '$CONTAINER_NAME' não está rodando."
        exit 1
    fi
    # Verifica banco
    if ! docker exec "$CONTAINER_NAME" psql -U "$ADMIN_USER" -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1; then
        echo "ERRO: Banco '$DB_NAME' não existe no container '$CONTAINER_NAME'."
        exit 1
    fi
    echo "Argumentos recebidos. Prosseguindo com: Container=$CONTAINER_NAME, Banco=$DB_NAME"
fi
# --- FIM DO BLOCO NOVO ---

echo "================================================================"
echo "           SELEÇÃO DE CONTAINER POSTGRES                        "
echo "================================================================"

# Só entra na seleção se CONTAINER_NAME estiver vazio
if [ -z "$CONTAINER_NAME" ]; then
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
            CONTAINER_NAME=$(echo "${CONTAINERS[$((CHOICE-1))]}" | awk '{print $1}')
            break
        else
            echo "Opção inválida."
        fi
    done
    echo "Container selecionado: $CONTAINER_NAME"
    echo "----------------------------------------------------------------"
fi

echo "================================================================"
echo "           SELEÇÃO DE BANCO DE DADOS                            "
echo "================================================================"

# Só entra na seleção se DB_NAME estiver vazio
if [ -z "$DB_NAME" ]; then
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
fi

echo "================================================================"
echo "           ATIVAÇÃO DO EXTENSION PGVECTOR                       "
echo "           (Usando Admin: $ADMIN_USER)                          "
echo "================================================================"

echo "Verificando e ativando a extensão 'vector' no banco '$DB_NAME'..."

docker exec -i "$CONTAINER_NAME" psql -U "$ADMIN_USER" -d "$DB_NAME" -c "CREATE EXTENSION IF NOT EXISTS vector;"

echo "----------------------------------------------------------------"
echo "================================================================"
echo "  PROCESSO CONCLUÍDO COM SUCESSO!"
echo "  A extensão 'vector' foi habilitada com sucesso no banco '$DB_NAME'."
echo "================================================================"
