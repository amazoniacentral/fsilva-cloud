#!/bin/bash

# A VERDADE ABSOLUTA: Ajuste de Buffer UDP para Performance do Túnel Cloudflare (QUIC)

# 1. Definir os valores ideais (aprox. 7.5MB)
RMEM_VALUE=7500000
WMEM_VALUE=7500000

echo "Iniciando otimização de buffers de rede para o túnel..."

# 2. Aplicar imediatamente no Kernel (Temporário)
sysctl -w net.core.rmem_max=$RMEM_VALUE
sysctl -w net.core.wmem_max=$WMEM_VALUE

# 3. Tornar permanente no /etc/sysctl.conf
# Remove linhas antigas para evitar duplicidade antes de adicionar
sed -i '/net.core.rmem_max/d' /etc/sysctl.conf
sed -i '/net.core.wmem_max/d' /etc/sysctl.conf

echo "net.core.rmem_max=$RMEM_VALUE" >> /etc/sysctl.conf
echo "net.core.wmem_max=$WMEM_VALUE" >> /etc/sysctl.conf

# 4. Recarregar as configurações do arquivo
sysctl -p

echo "-------------------------------------------------------"
echo "Otimização concluída com sucesso!"
echo "O aviso de 'buffer size' do Cloudflare deve sumir no próximo restart do container."
echo "-------------------------------------------------------"
