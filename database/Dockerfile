FROM postgres:15-alpine

# Instala as dependências padrão de compilação do Alpine
RUN apk add --no-cache --virtual .build-deps \
    git \
    build-base \
    postgresql-dev

# Baixa e compila o pgvector oficial na versão estável compatível com Postgres 15
RUN cd /tmp && \
    git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && \
    make install

# Remove as dependências de compilação e limpa a pasta temporária
RUN rm -rf /tmp/pgvector && \
    apk del .build-deps
