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
    zlib-dev

WORKDIR /code

# Instala pip compatível e pip-tools para gerenciar requirements.in
RUN pip install --no-cache-dir "pip<25.0" && \
    pip install --no-cache-dir pip-tools

# Copia o arquivo de entrada das dependências
COPY requirements.in .

# Compila o requirements.in para requirements.txt e instala as dependências
RUN pip-compile requirements.in --output-file=requirements.txt && \
    pip install --no-cache-dir -r requirements.txt

# Copia o restante do código do projeto
COPY . .

# Expõe a porta que o Gunicorn vai rodar
EXPOSE 8000

# O comando real está no docker-compose, mas deixamos um fallback aqui
CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000"]
