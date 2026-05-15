#!/bin/bash
# Cores para o terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Define o arquivo de destino
TARGET_FILE="$HOME/.bashrc"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# ==========================================================
# 1. FUNÇÕES COMPLEXAS (Strings literais)
# ==========================================================
GTAG_FUNCTION="gtag() {
    local VERSION=\$1
    local DESC=\$2
    if [ -z \"\$DESC\" ]; then
        DESC=\$1
        LAST_TAG=\$(git describe --tags --abbrev=0 2>/dev/null | sed 's/v//')
        if [ -z \"\$LAST_TAG\" ]; then VERSION=\"1.0.0\"; else
            local IFS=.
            read -r major minor patch <<< \"\$LAST_TAG\"
            patch=\$((patch + 1))
            VERSION=\"\$major.\$minor.\$patch\"
        fi
        echo \"Auto-incrementando para versão: v\$VERSION\"
    fi
    if [ -z \"\$DESC\" ]; then
        echo \"ERRO: Descrição obrigatória.\"
        return 1
    fi
    git tag -a \"v\$VERSION\" -m \"\$DESC\"
    git push origin \"v\$VERSION\"
    if command -v gh &> /dev/null; then
        gh release create \"v\$VERSION\" --title \"Versão \$VERSION\" --notes \"\$DESC\"
        echo \"🚀 Release v\$VERSION publicada no GitHub!\"
    else
        echo \"⚠️ Tag enviada, mas instale o 'gh' para criar Releases automáticas.\"
    fi
}"

GCOMMIT_FUNCTION="gcommit() {
  git pull origin
  git submodule update --remote --recursive
  if [ -f \"package.json\" ]; then
    npm version patch --no-git-tag-version
  fi
  git add .
  git commit -m \"\${1:-Salvando Alterações}\"
  git push
}"

DEXEC_FUNCTION="dexec() {
  if [ -z \"\$1\" ]; then
    echo \"ERRO: O nome do container é obrigatório.\"
    echo \"Uso: dexec <nome-do-container>\"
    return 1
  fi
  docker exec -it \"\$1\" sh
}"

# ==========================================================
# 2. LISTA DE ALIASES
# ==========================================================
declare -a ALIASES=(
    "ll='ls -lah'"
    "cls='clear'"
    "volumes='cd /var/lib/docker/volumes'"
    "status='bash $SCRIPT_DIR/status.sh'"
    "start='bash $SCRIPT_DIR/deploy/setup.sh'"
    "atalhos='bash $SCRIPT_DIR/alias.sh'"
    "refresh='source $HOME/.bashrc'"
)

clear
echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}          INICIANDO ATUALIZAÇÃO DE ALIASES/FUNÇÕES${RESET}"
echo -e "${YELLOW}          $TARGET_FILE...${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# --- LIMPEZA DE FUNÇÕES ANTIGAS ---
# Remove blocos antigos (do nome da função até a chave de fechamento no início da linha)
sed -i '/gtag()/,/^}/d' "$TARGET_FILE"
sed -i '/gcommit()/,/^}/d' "$TARGET_FILE"
sed -i '/dexec()/,/^}/d' "$TARGET_FILE"

# Insere as novas funções no final do arquivo
echo "$GTAG_FUNCTION" >> "$TARGET_FILE"
echo "FUNÇÃO ATUALIZADA: gtag"

echo "$GCOMMIT_FUNCTION" >> "$TARGET_FILE"
echo "FUNÇÃO ATUALIZADA: gcommit"

echo "$DEXEC_FUNCTION" >> "$TARGET_FILE"
echo "FUNÇÃO ATUALIZADA: dexec"

# --- PROCESSANDO ALIASES (SUBSTITUIÇÃO TOTAL PELO NOME) ---
for NOVO_ALIAS in "${ALIASES[@]}"; do
    # Extrai o nome do alias (ex: ll)
    NOME_ALIAS=$(echo "$NOVO_ALIAS" | cut -d'=' -f1)
    LINHA_COMPLETA="alias $NOVO_ALIAS"
    
    # Se o nome do alias existir no arquivo (independente do valor), deleta a linha inteira
    if grep -q "^alias $NOME_ALIAS=" "$TARGET_FILE"; then
        sed -i "/^alias $NOME_ALIAS=/d" "$TARGET_FILE"
    else
        echo -e "${GREEN}ADICIONADO:${RESET} $NOME_ALIAS"
    fi
    
    # Adiciona a nova definição ao final
    echo "$LINHA_COMPLETA" >> "$TARGET_FILE"
done

# Aplica as mudanças
echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${GREEN}SUCESSO: Configurações atualizadas!${RESET}"

echo -e "\n${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}             CONFIGURAÇÕES ATUAIS (RESUMO):${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"
grep "^alias " "$TARGET_FILE" | tail -n 5
grep -q "gtag()" "$TARGET_FILE" && echo "Função gtag: Versionamento de código no git"
grep -q "gcommit()" "$TARGET_FILE" && echo "Função gcommit: Enviar Commit pronto"
grep -q "dexec()" "$TARGET_FILE" && echo "Função dexec: Entrar no container"

echo -e "\n${CYAN}-------------------- by Francisco Silva ----------------${RESET}\n"
