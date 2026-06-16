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
    poppler-utils \
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
    
# Copia o restante do codigo
COPY repos/sgn/ .
