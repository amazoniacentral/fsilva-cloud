FROM postgres:15-alpine

# Instala as dependências necessárias para compilar a extensão
RUN apk add --no-cache --virtual .build-deps \
    git \
    build-base \
    clang15 \
    llvm15

# Baixa e compila o pgvector oficial
RUN cd /tmp && \
    git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git && \
    cd pgvector && \
    make && \
    make install

# Limpa os arquivos temporários para manter a imagem leve
RUN rm -rf /tmp/pgvector && \
    apk del .build-deps
