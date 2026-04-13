#!/bin/bash

# Falha o script se qualquer comando der erro
set -e

echo "Aguardando banco de dados..."
# Opcional: Adicione um check aqui se tiver o netcat (nc) instalado

echo "Aplicando migrações..."
python manage.py migrate --noinput

echo "Coletando arquivos estáticos..."
python manage.py collectstatic --noinput

echo "Iniciando o servidor..."
exec gunicorn core.wsgi:application --bind 0.0.0.0:8000
