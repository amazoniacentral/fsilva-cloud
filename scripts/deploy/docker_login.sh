#!/bin/bash

# Solicita o usuário e o token via terminal (TTY)
read -p "Digite seu usuário do GitHub: " USERNAME
# O '-s' (silent) oculta o que você digita para maior segurança
read -sp "Digite seu token do GitHub (PAT): " TOKEN
echo "" # Adiciona uma quebra de linha após a entrada do token

echo "Autenticando no GHCR..."

# Realiza o login usando o token fornecido
echo "$TOKEN" | docker login ghcr.io -u "$USERNAME" --password-stdin

if [ $? -eq 0 ]; then
    echo "Login efetuado com sucesso. Iniciando deploy..."
else
    echo "Falha na autenticação. Verifique se o usuário e o token estão corretos."
    exit 1
fi
