#!/bin/bash

# Descobre o nome de todos os containers rodando que contêm "ollama" no nome
containers=$(docker ps --format '{{.Names}}' | grep -i ollama)

if [ -z "$containers" ]; then
    echo "Nenhum container Ollama encontrado rodando."
    exit 1
fi

# Itera sobre cada container encontrado e executa o comando de pull
for container in $containers; do
    echo "Baixando o modelo llama3.2 no container: $container..."
    docker exec -it "$container" ollama pull llama3.2
    echo "Concluído para o container: $container"
    echo "----------------------------------------"
done
