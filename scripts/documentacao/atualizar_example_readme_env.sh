#!/bin/bash

# ==============================================================================
# SCRIPT: atualizar_example_readme_env.sh
# DESCRIÇÃO: Localiza .env.example a partir da BASE_DIR, injeta o conteúdo no 
#            README.md correspondente e ignora profundidade em repos/*/*.
# ==============================================================================

# Definição das bases de diretório conforme solicitado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../..")

# Definição do diretório temporário para processamento
TEMP_DIR="${TMPDIR:-/tmp}"
if [ ! -d "$TEMP_DIR" ]; then TEMP_DIR="."; fi

echo "Iniciando busca em: $BASE_DIR"
echo "Ignorando profundidade em: $BASE_DIR/repos/*/*"

# 1. Localizar arquivos .env.example
# -path "$BASE_DIR/repos/*/*" -prune: Ignora subpastas dentro dos projetos em repos
find "$BASE_DIR" -path "$BASE_DIR/repos/*/*" -prune -o -name ".env.example" -type f -print | while read -r CAMINHO_ENV; do
    
    # Define o diretório onde o .env.example foi encontrado
    DIR_ATUAL=$(dirname "$CAMINHO_ENV")
    
    # Define o caminho do README.md no mesmo diretório
    ARQUIVO_MD="$DIR_ATUAL/README.md"
    
    # 2. Verificar se o README.md existe naquele diretório
    if [ -f "$ARQUIVO_MD" ]; then
        
        # Cria um arquivo temporário para o conteúdo
        ARQUIVO_TEMP=$(mktemp "$TEMP_DIR/env_XXXXXX.txt")
        
        # Extrai o conteúdo do .env.example
        cat "$CAMINHO_ENV" > "$ARQUIVO_TEMP"
        
        # Exporta para a variável que o Perl irá utilizar (preservando quebras de linha)
        export CONTEUDO_TREE=$(cat "$ARQUIVO_TEMP")
        
        # 3. Inserir no README.md usando Perl
        # Substitui o bloco ```env.example ... ``` pelo novo conteúdo
        perl -i -0777 -pe 's/```env.example.*?```/```env.example\n$ENV{CONTEUDO_TREE}\n```/gs' "$ARQUIVO_MD"
        
        # Limpeza do arquivo temporário
        rm -f "$ARQUIVO_TEMP"
        
        echo "Atualizado: $ARQUIVO_MD"
    fi
done

echo "Concluído!"
