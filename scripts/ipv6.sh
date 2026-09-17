#!/bin/bash

# Garante que o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "Execute este script como root (sudo)."
  exit 1
fi

echo "Verificando se o servidor possui suporte/conectividade IPv6..."

# Testa se há conectividade IPv6 usando o Google (endereço público IPv6)
if ping6 -c 1 2001:4860:4860::8888 &> /dev/null || ip -6 addr show scope global | grep -q "inet6"; then
    echo "-> IPv6 detectado e aceito pelo servidor."
    IPV6_STATUS="true"
else
    echo "-> IPv6 NÃO é suportado ou está inacessível neste servidor."
    IPV6_STATUS="false"
fi

# Define o caminho do arquivo de configuração do Docker
DAEMON_FILE="/etc/docker/daemon.json"

echo "Atualizando a configuração do Docker ($DAEMON_FILE)..."

# Cria ou atualiza o daemon.json mantendo a sintaxe JSON correta
if [ -f "$DAEMON_FILE" ]; then
    # Se o arquivo já existe, podemos usar jq ou reescrever de forma segura
    # Garantindo a propriedade ipv6
    python3 -c "
import json
path = '$DAEMON_FILE'
try:
    with open(path, 'r') as f:
        data = json.load(f)
except Exception:
    data = {}
data['ipv6'] = $IPV6_STATUS
with open(path, 'w') as f:
    json.dump(data, f, indent=4)
"
else
    # Se o arquivo não existe, cria um novo
    mkdir -p /etc/docker
    cat <<EOF > "$DAEMON_FILE"
{
  "ipv6": $IPV6_STATUS
}
EOF
fi

echo "Reiniciando o serviço do Docker..."
systemctl restart docker

echo "Concluído! O IPv6 no Docker foi configurado como: $IPV6_STATUS"
