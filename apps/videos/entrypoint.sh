#!/bin/sh

# Lista de pacotes que você quer garantir que existam
PACOTES="express multer fluent-ffmpeg cors"

echo "Verificando dependências: $PACOTES"

# O comando npm install com --save vai atualizar o package.json 
# automaticamente na sua pasta local (devido ao volume montado)
npm install $PACOTES --save

echo "Dependências atualizadas no package.json!"

# Mantém o container rodando
# exec tail -f /dev/null
exec npm run dev
