#!/bin/bash
set -e

echo "================================================================"
echo "    LIMPEZA GLOBAL DE CERTIFICADOS ACME (TODOS OS TRAEFIKS)     "
echo "================================================================"

# Mapeia todos os containers em execução que possuem 'traefik' no nome
mapfile -t CONTAINERS < <(docker ps --format "{{.Names}}" | grep -i "traefik")

if [ ${#CONTAINERS[@]} -eq 0 ]; then
    echo "AVISO: Nenhum container Traefik em execução encontrado."
    exit 0
fi

echo "Foram encontrados ${#CONTAINERS[@]} container(s) Traefik ativos."
echo "----------------------------------------------------------------"

BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Loop por cada container Traefik encontrado
for TRAEFIK_CONTAINER in "${CONTAINERS[@]}"; do
    echo "Processando container: $TRAEFIK_CONTAINER"

    # Descobre o volume ACME montado em /etc/traefik/acme
    ACME_VOLUME=$(docker inspect "$TRAEFIK_CONTAINER" --format '{{range .Mounts}}{{if eq .Destination "/etc/traefik/acme"}}{{.Name}}{{end}}{{end}}')

    if [ -z "$ACME_VOLUME" ]; then
        echo "  -> AVISO: Volume /etc/traefik/acme não encontrado em $TRAEFIK_CONTAINER. Pulando..."
        continue
    fi

    echo "  -> Volume ACME identificado: $ACME_VOLUME"
    echo "  -> Criando backup e limpando acme.json..."

    # Executa container Alpine temporário para gerenciar o volume de forma isolada e segura
    docker run --rm -v "$ACME_VOLUME:/acme_data" alpine sh -c "
        mkdir -p /acme_data/backups
        if [ -f /acme_data/acme.json ]; then
            cp /acme_data/acme.json /acme_data/backups/acme_$BACKUP_TIMESTAMP.json.bak
            # Mantém apenas os últimos 15 backups
            ls -t /acme_data/backups/*.bak | tail -n +16 | xargs -r rm
        fi
        # Reseta o arquivo acme.json com permissões restritas (600)
        echo '{}' > /acme_data/acme.json
        chmod 600 /acme_data/acme.json
    "

    echo "  -> Reiniciando $TRAEFIK_CONTAINER..."
    docker restart "$TRAEFIK_CONTAINER"
    echo "  -> Concluído para $TRAEFIK_CONTAINER."
    echo "----------------------------------------------------------------"
done

echo "================================================================"
echo "  PROCESSO GLOBAL CONCLUÍDO COM SUCESSO!"
echo "  Todos os containers Traefik ativos tiveram seus acme.json limpos."
echo "================================================================"
