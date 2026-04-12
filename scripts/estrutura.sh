#!/bin/bash

# ==============================================================================
# SCRIPT: atualizar_readme.sh (Localizado em /scripts)
# DESCRIÇÃO: Gera a estrutura e injeta dentro do bloco ```estrutura
# ==============================================================================

# Caminhos relativos
ARQUIVO_MD="../README.md"
DIRETORIO_RAIZ=".."
ARQUIVO_TEMP="estrutura_temp.txt"

# 1. Verificar se o tree está instalado
if ! command -v tree &> /dev/null; then
    sudo apt update && sudo apt install tree -y
fi

# 2. Verificar se o arquivo README.md existe
if [ ! -f "$ARQUIVO_MD" ]; then
    echo "Erro: Arquivo $ARQUIVO_MD não encontrado."
    exit 1
fi

# 3. Gerar a estrutura de pastas a partir da RAIZ
# -a: ocultos | -I: ignora lixo | -L 3: profundidade para submodules
tree -a -I '.git|.github|node_modules' -L 3 --dirsfirst "$DIRETORIO_RAIZ" > "$ARQUIVO_TEMP"

# 4. Criar o novo bloco de conteúdo
# Mantemos as cercas de código como parte da substituição
ESTRUTURA_GERADA=$(cat "$ARQUIVO_TEMP")

# 5. Inserir no README.md usando Perl
# A VERDADE ABSOLUTA: A regex procura por ```estrutura, captura o que tem dentro até o próximo ``` e substitui.
export CONTEUDO_TREE="$ESTRUTURA_GERADA"
perl -i -0777 -pe 's/```estrutura.*?```/```estrutura\n$ENV{CONTEUDO_TREE}\n```/gs' "$ARQUIVO_MD"

# 6. Limpeza
if [ -f "$ARQUIVO_TEMP" ]; then rm "$ARQUIVO_TEMP"; fi

echo "Sucesso: Estrutura injetada dentro do bloco \`\`\`estrutura!"
