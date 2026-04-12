#!/bin/bash

# ==============================================================================
# SCRIPT: atualizar_readme.sh (Localizado em /scripts)
# DESCRIÇÃO: Gera a estrutura da raiz e injeta no README.md da raiz.
# ==============================================================================

# Caminhos relativos a partir da pasta /scripts
ARQUIVO_MD="../README.md"
DIRETORIO_RAIZ=".."
MARCADOR_INICIO=""
MARCADOR_FIM=""
ARQUIVO_TEMP="estrutura_temp.txt"
ARQUIVO_BLOCO="bloco_markdown.txt"

# 1. Verificar se o arquivo README.md existe
if [ ! -f "$ARQUIVO_MD" ]; then
    echo "Erro: Arquivo $ARQUIVO_MD não encontrado."
    exit 1
fi

# 2. Gerar a estrutura de pastas a partir da RAIZ
# -a: arquivos ocultos
# -I: ignora git, github e node_modules
# -L 3: profundidade para não detalhar submodules em /repos
# O comando roda no diretório pai (..)
tree -a -I '.git|.github|node_modules' -L 3 "$DIRETORIO_RAIZ" > "$ARQUIVO_TEMP"

# 3. Criar o bloco formatado para o Markdown
{
    echo "$MARCADOR_INICIO"
    echo '```text'
    cat "$ARQUIVO_TEMP"
    echo '```'
    echo "$MARCADOR_FIM"
} > "$ARQUIVO_BLOCO"

# 4. Inserir o bloco no README.md
# Usando Perl para garantir compatibilidade com blocos multilinhas e evitar problemas com o sed
export NOVO_CONTEUDO=$(cat "$ARQUIVO_BLOCO")
perl -i -0777 -pe 's/.*?/$ENV{NOVO_CONTEUDO}/gs' "$ARQUIVO_MD"

# 5. Limpar arquivos temporários
if [ -f "$ARQUIVO_TEMP" ]; then rm "$ARQUIVO_TEMP"; fi
if [ -f "$ARQUIVO_BLOCO" ]; then rm "$ARQUIVO_BLOCO"; fi

echo "README.md atualizado com a estrutura de diretórios a partir da raiz!"
