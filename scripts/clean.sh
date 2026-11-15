#!/bin/bash

echo "========================================="
echo "       LIMPEZA SEGURA DO DOCKER          "
echo "========================================="

echo "[1/4] Removendo recursos ociosos (containers parados, redes e imagens órfãs)..."
docker system prune -f

echo "[2/4] Removendo todo o cache de build do Docker..."
docker builder prune -a -f

echo "[3/4] Removendo imagens antigas..."
docker image prune -a -f

echo "[4/4] Limpando cache do apt..."
apt-get clean

echo "========================================="
echo "       LIMPEZA CONCLUÍDA COM SUCESSO!    "
echo "========================================="
