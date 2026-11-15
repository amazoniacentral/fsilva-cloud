#!/bin/bash
clear
echo "========================================="
echo "       LIMPEZA SEGURA DO DOCKER          "
echo "========================================="

echo "📊 Espaço em disco ANTES da limpeza:"
df -h /
echo "-----------------------------------------"

# Captura o espaço disponível em blocos de 1KB antes da limpeza
BEFORE_KB=$(df / | awk 'NR==2 {print $4}')

echo "[1/4] Removendo recursos ociosos (containers parados, redes e imagens órfãs)..."
docker system prune -f

echo "[2/4] Removendo todo o cache de build do Docker..."
docker builder prune -a -f

echo "[3/4] Removendo imagens antigas..."
docker image prune -a -f

echo "[4/4] Limpando cache do apt..."
apt-get clean

echo "-----------------------------------------"
echo "📊 Espaço em disco DEPOIS da limpeza:"
df -h /
echo "========================================="

# Captura o espaço disponível em blocos de 1KB depois da limpeza
AFTER_KB=$(df / | awk 'NR==2 {print $4}')
FREED_KB=$((AFTER_KB - BEFORE_KB))

# Exibe o total liberado convertido de forma legível
if [ $FREED_KB -gt 1048576 ]; then
    FREED_GB=$(awk "BEGIN {print $FREED_KB / 1048576}")
    printf "✨ Espaço total liberado: ~%.2f GB\n" "$FREED_GB"
elif [ $FREED_KB -gt 1024 ]; then
    FREED_MB=$(awk "BEGIN {print $FREED_KB / 1024}")
    printf "✨ Espaço total liberado: ~%.2f MB\n" "$FREED_MB"
else
    echo "✨ Espaço total liberado: ${FREED_KB} KB"
fi

echo "========================================="
echo "       LIMPEZA CONCLUÍDA COM SUCESSO!    "
echo "========================================="
