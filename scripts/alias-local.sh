#!/bin/sh

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

TARGET_FILE="$HOME/.profile"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

clear

echo "${CYAN}--------------------------------------------------------${RESET}"
echo "${YELLOW} ATUALIZANDO ALIASES E FUNÇÕES DE SHELL${RESET}"
echo "${CYAN}--------------------------------------------------------${RESET}"

# ==========================================================
# LIMPA FUNÇÕES ANTIGAS
# ==========================================================
sed -i '/^gtag()/,/^}/d' "$TARGET_FILE"
sed -i '/^gcommit()/,/^}/d' "$TARGET_FILE"
sed -i '/^dexec()/,/^}/d' "$TARGET_FILE"

# ==========================================================
# GTAG (VERSÃO COMPATÍVEL)
# ==========================================================
cat <<'EOF' >> "$TARGET_FILE"
gtag() {
    VERSION=$1
    DESC=$2

    if [ -z "$DESC" ]; then
        DESC="$1"

        LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/v//')

        if [ -z "$LAST_TAG" ]; then
            VERSION="1.0.0"
        else
            major=$(echo "$LAST_TAG" | cut -d. -f1)
            minor=$(echo "$LAST_TAG" | cut -d. -f2)
            patch=$(echo "$LAST_TAG" | cut -d. -f3)

            patch=$((patch + 1))
            VERSION="$major.$minor.$patch"
        fi

        echo "Auto-incrementando versão: v$VERSION"
    fi

    if [ -z "$DESC" ]; then
        echo "ERRO: Descrição obrigatória"
        return 1
    fi

    git tag -a "v$VERSION" -m "$DESC"
    git push origin "v$VERSION"

    if command -v gh >/dev/null 2>&1; then
        gh release create "v$VERSION" --title "Versão $VERSION" --notes "$DESC"
        echo "Release publicada"
    else
        echo "gh não instalado"
    fi
}
EOF

# ==========================================================
# GCOMMIT
# ==========================================================
cat <<'EOF' >> "$TARGET_FILE"
gcommit() {
    git pull origin
    git submodule update --remote --recursive

    if [ -f "package.json" ]; then
        npm version patch --no-git-tag-version
    fi

    git add .
    git commit -m "${1:-Salvando Alterações}"
    git push
}
EOF

# ==========================================================
# DEXEC
# ==========================================================
cat <<'EOF' >> "$TARGET_FILE"
dexec() {
    if [ -z "$1" ]; then
        echo "Uso: dexec <container>"
        return 1
    fi

    docker exec -it "$1" sh
}
EOF

# ==========================================================
# ALIASES (compatível)
# ==========================================================
ALIASES="
alias ll='ls -lah'
alias cls='clear'
alias volumes='cd /var/lib/docker/volumes'
alias status='bash $SCRIPT_DIR/status.sh'
alias limpar='bash $SCRIPT_DIR/clean.sh'
alias start='bash $SCRIPT_DIR/deploy/setup.sh'
alias atalhos='bash $SCRIPT_DIR/alias.sh'
alias refresh='source $HOME/.profile'
"

echo "$ALIASES" >> "$TARGET_FILE"

echo "${GREEN}SUCESSO: Configurações aplicadas com segurança!${RESET}"

echo ""
echo "Resumo:"
grep '^alias ' "$TARGET_FILE" | tail -n 5
echo "gtag: OK"
echo "gcommit: OK"
echo "dexec: OK"