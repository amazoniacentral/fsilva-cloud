# Estágio 1: Build da aplicação
FROM node:20-alpine AS build-stage
WORKDIR /app

# Configura o limite de memória do Node.js para 1GB
ENV NODE_OPTIONS="--max-old-space-size=1024"

# 1. Dependências
COPY repos/gvendas/package*.json ./
RUN npm install

# 2. Código e Env
COPY repos/gvendas/ .
COPY gvendas-suite/app-react/.env .env

# 3. Build (gera em /app/build)
RUN npm run build

# Estágio 2: Nginx
FROM nginx:stable-alpine

# Criamos um diretório temporário para guardar o build antes do volume ser montado
WORKDIR /app_temp
COPY --from=build-stage /app/build .

# Copia a configuração do Nginx
COPY gvendas-suite/app-react/app_nginx.conf /etc/nginx/conf.d/default.conf

# Script para copiar os arquivos para o volume na hora que o container subir
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'cp -rp /app_temp/. /usr/share/nginx/html/' >> /entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 80

WORKDIR /usr/share/nginx
# O entrypoint garante que, mesmo com volume montado, os arquivos sejam copiados para lá
ENTRYPOINT ["/entrypoint.sh"]
