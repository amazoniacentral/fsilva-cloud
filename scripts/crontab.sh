#!/bin/bash

# ==========================================================
# LISTA DE TAREFAS PARA O CRONTAB (Adicione novas aqui)
# Formato: "MINUTO HORA DIA_MES MES DIA_SEMANA COMANDO"
# ==========================================================
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")
LOGS_DIR=$(readlink -f "$SCRIPT_DIR/../logs")

declare -a TAREFAS=(
    "0 3 * * 0 /bin/docker builder prune -f && /bin/docker image prune -a -f"
    "0 */12 * * * /sbin/htpdate -s -t google.com"
    "0 3 * * 0 /bin/bash $SCRIPT_DIR/limpar_traefik.sh >> $LOGS_DIR/limpeza_traefik.log 2>&1"
    "* * * * * /bin/bash $SCRIPT_DIR/backup_db.sh && /bin/bash $SCRIPT_DIR/backup_rclone.sh >> $LOGS_DIR/backup.log 2>&1"
    "0 4 * * * /bin/bash $SCRIPT_DIR/backup_rclone.sh >> $LOGS_DIR/backup_rclone.log 2>&1"
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
