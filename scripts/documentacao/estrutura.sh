#!/bin/bash

# ==============================================================================
# SCRIPT: atualizar_readme.sh (Localizado em /scripts)
# DESCRIÇÃO: Gera a estrutura e injeta no bloco ```estrutura (Portátil)
# ==============================================================================

# Caminhos relativos
ARQUIVO_MD="../../README.md"
DIRETORIO_RAIZ=".."

# Definição do diretório temporário (Usa $TMPDIR se existir, senão usa /tmp, senão pasta atual)
TEMP_DIR="${TMPDIR:-/tmp}"
if [ ! -d "$TEMP_DIR" ]; then TEMP_DIR="."; fi

# mktemp cria um arquivo seguro. O '.' garante que funcione mesmo sem /tmp
ARQUIVO_TEMP=$(mktemp "$TEMP_DIR/estrutura_XXXXXX.txt")

# 1. Verificar se o tree está instalado
if ! command -v tree &> /dev/null; then
    sudo apt update && sudo apt install tree -y
fi

# 2. Verificar se o arquivo README.md existe
if [ ! -f "$ARQUIVO_MD" ]; then
    echo "Erro: Arquivo $ARQUIVO_MD não encontrado."
    rm -f "$ARQUIVO_TEMP"
    exit 1
fi

# 3. Gerar a estrutura de pastas a partir da RAIZ
# -a: ocultos | -I: ignora lixo e subpastas de repos | -L 3: profundidade
tree -a -I '.git|.github|node_modules|repos/*/*' -L 3 --dirsfirst "$DIRETORIO_RAIZ" > "$ARQUIVO_TEMP"

# 4. Preparar o conteúdo para injeção
ESTRUTURA_GERADA=$(cat "$ARQUIVO_TEMP")
export CONTEUDO_TREE="$ESTRUTURA_GERADA"

# 5. Inserir no README.md usando Perl
# Regex busca o bloco e adiciona \n após o fechamento para quebrar linha
perl -i -0777 -pe 's/```estrutura.*?```/```estrutura\n$ENV{CONTEUDO_TREE}\n```/gs' "$ARQUIVO_MD"

# 6. Limpeza do arquivo temporário
rm -f "$ARQUIVO_TEMP"

echo "Sucesso: Estrutura atualizada no README.md!"
