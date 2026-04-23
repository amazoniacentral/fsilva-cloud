# Usamos a versão Alpine por ser extremamente leve (ideal para VPS)
FROM python:3.11-alpine

# Define que o Python não deve gerar arquivos .pyc e deve exibir logs em tempo real
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Instala dependências de sistema necessárias
RUN apk add --no-cache \
    gcc \
    musl-dev \
    postgresql-dev \
    libffi-dev \
    jpeg-dev \
    zlib-dev \
    bash

WORKDIR /code

# Instala pip compatível e pip-tools
RUN pip install --no-cache-dir "pip<25.0" && \
    pip install --no-cache-dir pip-tools

# 1. COPIA o arquivo de entrada das dependências
COPY repos/sgn/requirements.in .

# Compila e instala as dependências
RUN pip-compile requirements.in --output-file=requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# 2. COPIA o restante do código
COPY repos/sgn/ .

# Cria o script de entrypoint que executa migrações e DEPOIS o comando do Compose
RUN printf "#!/bin/bash\n\
echo 'Aplicando migrações...'\n\
python manage.py migrate --noinput\n\
\n\
echo 'Coletando arquivos estáticos...'\n\
python manage.py collectstatic --noinput\n\
\n\
echo 'Checando Sites...'\n\
python manage.py gerar_sites_html\n\
\n\
echo 'Executando comando:' \"\$@\"\n\
exec \"\$@\"\n" > /entrypoint.sh

# Dá permissão de execução
RUN chmod +x /entrypoint.sh

# Expõe a porta
EXPOSE 8000

# Define o entrypoint
ENTRYPOINT ["/entrypoint.sh"]
