#!/bin/bash

echo "========================================="
echo "       LIMPEZA SEGURA DO DOCKER          "
echo "========================================="

echo "[1/3] Removendo cache de build do Docker..."
docker builder prune -a -f

echo "[2/3] Removendo imagens antigas/órfãs..."
docker image prune -a -f

echo "[3/3] Limpando cache do apt..."
apt-get clean

echo "========================================="
echo "       LIMPEZA CONCLUÍDA COM SUCESSO!    "
echo "========================================="
