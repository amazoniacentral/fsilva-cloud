#!/bin/bash

# ==========================================================
# LISTA DE TAREFAS PARA O CRONTAB (Adicione novas aqui)
# Formato: "MINUTO HORA DIA_MES MES DIA_SEMANA COMANDO"
# ==========================================================
declare -a TAREFAS=(
    "0 3 * * 0 /usr/bin/docker builder prune -f"
    "0 4 * * 0 /usr/bin/docker image prune -f"
    "0 */12 * * * /usr/sbin/htpdate -s -t google.com"
    "0 3 * * 0 /usr/bin/bash /opt/fsilva-cloud/scripts/limpar_traefik.sh >> /var/log/limpeza_traefik.log 2>&1"
    "0 4 * * * /usr/bin/bash /opt/fsilva-cloud/scripts/backup_media.sh"
)

echo "--------------------------------------------------------"
echo "INICIANDO ATUALIZAÇÃO DO CRONTAB..."
echo "--------------------------------------------------------"

# 1. Lê o crontab atual para um arquivo temporário
TMP_CRON=$(mktemp)
crontab -l 2>/dev/null > "$TMP_CRON"

MUDOU=false

# 2. Itera sobre a lista de tarefas
for TAREFA in "${TAREFAS[@]}"; do
    if grep -Fq "$TAREFA" "$TMP_CRON"; then
        echo "IGNORADO: A tarefa já existe: $TAREFA"
    else
        echo "$TAREFA" >> "$TMP_CRON"
        echo "ADICIONADO: $TAREFA"
        MUDOU=true
    fi
done

# 3. Aplica o novo crontab se houver mudanças
if [ "$MUDOU" = true ]; then
    crontab "$TMP_CRON"
    echo "--------------------------------------------------------"
    echo "SUCESSO: Crontab atualizado com novas tarefas!"
else
    echo "--------------------------------------------------------"
    echo "AVISO: Nenhuma tarefa nova para adicionar."
fi

rm "$TMP_CRON"

echo "--------------------------------------------------------"
echo "SEU CRONTAB ATUAL:"
crontab -l
