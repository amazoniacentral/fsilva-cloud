#!/bin/bash

# ==========================================================
# LISTA DE TAREFAS PARA O CRONTAB (Adicione novas aqui)
# ==========================================================
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")
LOGS_DIR=$(readlink -f "$SCRIPT_DIR/../logs")

# Garante que a pasta de logs existe
mkdir -p "$LOGS_DIR"

declare -a TAREFAS=(
    "0 3 * * 0 /usr/bin/docker builder prune -f && /usr/bin/docker image prune -a -f"
    "0 */12 * * * /sbin/htpdate -s -t google.com"
    "0 3 * * 0 (echo \"--- Limpeza: \$(date '+%Y-%m-%d %H:%M:%S') ---\" && /usr/bin/bash $SCRIPT_DIR/limpar_traefik.sh) >> $LOGS_DIR/limpeza_traefik.log 2>&1"
    "* * * * * /usr/bin/flock -n /tmp/gvendas_backup.lock /usr/bin/bash -c \"echo --- Inicio: \\\$(date '+%Y-%m-%d %H:%M:%S') --- && /usr/bin/bash $SCRIPT_DIR/backup_db.sh && /usr/bin/bash $SCRIPT_DIR/backup_rclone.sh && echo --- Fim: \\\$(date '+%Y-%m-%d %H:%M:%S') ---\" >> $LOGS_DIR/backup.log 2>&1"
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
    echo "As tarefas antigas que não estavam na lista foram removidas."
else
    echo "ERRO: Falha ao aplicar o Crontab."
fi

# 4. Limpeza
rm "$TMP_CRON"

echo "--------------------------------------------------------"
echo "SEU CRONTAB ATUAL (LIMPO E ATUALIZADO):"
chmod -R 755 $SCRIPT_DIR
chmod +x $SCRIPT_DIR/*.sh
crontab -l
