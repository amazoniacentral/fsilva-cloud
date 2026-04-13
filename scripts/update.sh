#!/bin/bash

# Define a branch que você deseja aplicar a todos os submódulos
TARGET_BRANCH="main"

echo "Iniciando a atualização dos submódulos para a branch: $TARGET_BRANCH"

# Percorre todos os caminhos de submódulos registrados no .gitmodules
git config --file .gitmodules --get-regexp path | awk '{ print $2 }' | while read -r module_path; do
    echo "--------------------------------------------------------"
    echo "Processando submódulo: $module_path"

    # 1. Configura a branch no .gitmodules
    git config -f .gitmodules submodule."$module_path".branch "$TARGET_BRANCH"
    
    # 2. Sincroniza a URL (caso tenha mudado no remoto)
    git submodule sync -- "$module_path"
    
    # 3. Atualiza o conteúdo para o commit mais recente da branch alvo
    git submodule update --remote --merge -- "$module_path"
    
    echo "Submódulo $module_path atualizado para $TARGET_BRANCH."
done

# Adiciona as alterações ao stage
echo "--------------------------------------------------------"
echo "Finalizando e adicionando alterações ao Git..."
git add .gitmodules
git add .

echo "Pronto! Agora basta você executar: git commit -m 'Fixando todos os submódulos na branch $TARGET_BRANCH'"
