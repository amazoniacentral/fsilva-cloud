#!/bin/bash

# ==========================================================
# LISTA DE TAREFAS PARA O CRONTAB (Adicione novas aqui)
# ==========================================================
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")
LOGS_DIR=$(readlink -f "$SCRIPT_DIR/../logs")

# Garante que a pasta de logs existe
mkdir -p "$LOGS_DIR"

# A VERDADE: Para interpretar \n, o echo precisa do parâmetro -e
# Usamos \$ para garantir que o comando date rode apenas no Cron
DATA_LOG="\\n\\n== \$(date '+\%Y-\%m-\%d \%H:\%M:\%S') == "

declare -a TAREFAS=(
    "0 */12 * * * /sbin/htpdate -s -t google.com >> $LOGS_DIR/cron.log 2>&1"
    "0 3 * * 0 (echo -e \"$DATA_LOG Limpeza VPS\" && /usr/bin/docker builder prune -f && /usr/bin/docker image prune -a --force) >> $LOGS_DIR/cron.log 2>&1"
    "0 3 * * * /usr/bin/flock -n /tmp/gvendas_backup.lock /usr/bin/bash -c \"echo -e \\\"$DATA_LOG Backup Diário\\\" && /usr/bin/bash $SCRIPT_DIR/backup_db.sh && /usr/bin/bash $SCRIPT_DIR/backup_rclone.sh\" >> $LOGS_DIR/cron.log 2>&1"
    "0 4 * * 0 (echo -e \"$DATA_LOG Limpeza Traefik\" && /usr/bin/bash $SCRIPT_DIR/limpar_traefik.sh) >> $LOGS_DIR/cron.log 2>&1"
    "*/16 * * * * (echo -e \"$DATA_LOG Sync Backups\" && /usr/bin/bash $SCRIPT_DIR/backup/sync_rclone.sh) >> $LOGS_DIR/cron.log 2>&1"
    "*/14 * * * * (echo -e \"$DATA_LOG Copy Backups\" && /usr/bin/bash $SCRIPT_DIR/backup/copy_rclone.sh) >> $LOGS_DIR/cron.log 2>&1"
)


echo "--------------------------------------------------------"
echo "SINCRONIZANDO CRONTAB COM A LISTA ATUAL..."
echo "--------------------------------------------------------"

# 1. Cria um arquivo temporário com as novas tarefas
TMP_CRON=$(mktemp)

# 2. Converte o Array em linhas de texto dentro do arquivo temporário
printf "%s\n" "${TAREFAS[@]}" > "$TMP_CRON"

# 3. Aplica o arquivo temporário como o novo Crontab (Isso remove as antigas)
if crontab "$TMP_CRON"; then
    echo "SUCESSO: Crontab atualizado e limpo!"
else
    echo "ERRO: Falha ao aplicar o Crontab."
fi

# 4. Limpeza e Permissões
rm "$TMP_CRON"
chmod -R 755 "$SCRIPT_DIR"
chmod +x "$SCRIPT_DIR"/*.sh

echo "--------------------------------------------------------"
echo "SEU CRONTAB ATUAL (LIMPO E ATUALIZADO):"
crontab -l
