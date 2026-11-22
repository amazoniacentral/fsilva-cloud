FROM postgres:15-alpine

# Instala dependências, baixa, compila o pgvector (sem LLVM) e limpa tudo na mesma camada
RUN apk add --no-cache --virtual .build-deps \
    git \
    build-base \
    postgresql-dev && \
    cd /tmp && \
    git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make with_llvm=no && \
    make with_llvm=no install && \
    cd / && \
    rm -rf /tmp/pgvector && \
    apk del .build-deps
