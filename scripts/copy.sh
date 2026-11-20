#!/bin/bash
set -e

# Verifica e instala o rsync automaticamente se não estiver disponível
if ! command -v rsync &> /dev/null; then
    echo "⚙️ rsync não encontrado. Instalando..."
    sudo apt-get update -y &>/dev/null
    sudo apt-get install -y rsync &>/dev/null
    echo "✅ rsync instalado com sucesso!"
fi

echo "=========================================="
echo "    CÓPIA SEGURA (SEM SOBRESCREVER)       "
echo "=========================================="

# Solicita os caminhos ao usuário (o -e habilita autocompletar com Tab no terminal)
read -e -p "📂 De onde deseja copiar (Origem): " ORIGEM
read -e -p "📁 Para onde deseja copiar (Destino): " DESTINO

# Valida se a origem foi informada e se existe
if [ -z "$ORIGEM" ] || [ ! -d "$ORIGEM" ]; then
    echo "❌ Erro: O diretório de origem '$ORIGEM' não existe ou é inválido."
    exit 1
fi

if [ -z "$DESTINO" ]; then
    echo "❌ Erro: O diretório de destino não pode ficar vazio."
    exit 1
fi

# Garante que a origem termine com '/' para copiar o conteúdo interno (incluindo arquivos ocultos)
ORIGEM="${ORIGEM%/}/"

# Cria o diretório de destino caso ele ainda não exista
mkdir -p "$DESTINO"

echo ""
echo "🚀 Copiando de '$ORIGEM' para '$DESTINO' (ignorando arquivos existentes)..."
rsync -av --ignore-existing --no-perms --no-owner --no-group "$ORIGEM" "$DESTINO"

echo ""
echo "✅ Cópia concluída com sucesso!"
