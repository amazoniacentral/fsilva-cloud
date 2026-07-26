#!/bin/bash

# ==========================================================
# SCRIPT DE TAG E RELEASE (Execução Direta)
# ==========================================================

# Cores para o terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RESET='\033[0m'

VERSION=$1
DESC=$2

# Lógica de Auto-incremento (se não foi passada versão manual)
if [ -z "$DESC" ] && [ -n "$VERSION" ]; then
    DESC="$VERSION"
    VERSION=""
fi

if [ -z "$VERSION" ]; then
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
    echo -e "${YELLOW}Auto-incrementando para: v$VERSION${RESET}"
fi

if [ -z "$DESC" ]; then
    echo -e "${YELLOW}ERRO: Descrição obrigatória.${RESET}"
    echo "Uso: ./gtag.sh 'descrição'  OU  ./gtag.sh 1.0.1 'descrição'"
    exit 1
fi

# Execução Git
echo -e "${CYAN}Criando tag v$VERSION...${RESET}"
git tag -a "v$VERSION" -m "$DESC"
git push origin "v$VERSION"

# Execução GitHub Release
if command -v gh >/dev/null 2>&1; then
    gh release create "v$VERSION" --title "Versão $VERSION" --notes "$DESC"
    echo -e "${GREEN}Release v$VERSION publicada com sucesso!${RESET}"
else
    echo -e "${YELLOW}Aviso: 'gh' não encontrado. Apenas a tag foi enviada.${RESET}"
fi
