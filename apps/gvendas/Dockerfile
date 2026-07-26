# Estágio 1: Build
FROM node:20-alpine AS build-stage
WORKDIR /app
COPY repos/gvendas/package*.json ./
RUN npm install
COPY repos/gvendas/ .
# Build (O GitHub Actions gerencia os recursos, não precisamos de ENV aqui)
RUN export VERSION=$(node -p "require('./package.json').version") && \
    echo "Construindo versão: $VERSION" && \
    REACT_APP_VERSION=$VERSION GENERATE_SOURCEMAP=false npm run build

# Estágio 2: Nginx (Runtime)
FROM nginx:stable-alpine

# FIX 1: Instala o gettext para ter acesso ao envsubst
RUN apk add --no-cache gettext

WORKDIR /usr/share/nginx/html

# Copia do build diretamente para o local final
COPY --from=build-stage /app/build .

# Configurações do Nginx
COPY apps/auth-nginx.conf /etc/nginx/auth-nginx.conf
COPY apps/gvendas/nginx.conf /etc/nginx/conf.d/default.conf

# FIX 2: Script que substitui as variáveis ANTES de iniciar o Nginx
RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'envsubst "\$API_DOMAIN \$META_APP_ID \$CONFIG_ID" < index.html > index.html.tmp' >> /entrypoint.sh && \
    echo 'mv index.html.tmp index.html' >> /entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
