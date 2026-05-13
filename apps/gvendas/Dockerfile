# Estágio 1: Build da aplicação
FROM node:20-alpine AS build-stage
WORKDIR /app

# Configura o limite de memória do Node.js para 1GB
ENV NODE_OPTIONS="--max-old-space-size=1024"

# 1. Dependências
COPY ../../repos/gvendas/package*.json ./
RUN npm install

# 2. Código
COPY ../../repos/gvendas/ .

# 3. Build com injeção automática da versão do package.json
# O CRA vai capturar o REACT_APP_VERSION e gravar no build estático
ARG REACT_APP_API_DOMAIN
ENV REACT_APP_API_DOMAIN=$REACT_APP_API_DOMAIN

RUN export VERSION=$(node -p "require('./package.json').version") && \
    echo "Construindo versão: $VERSION" && \
    REACT_APP_VERSION=$VERSION npm run build

# Estágio 2: Nginx
FROM nginx:stable-alpine

WORKDIR /app_temp
COPY --from=build-stage /app/build .

COPY ../auth-nginx.conf /etc/nginx/auth-nginx.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN echo '#!/bin/sh' > /entrypoint.sh && \
    echo 'cp -rp /app_temp/. /usr/share/nginx/html/' >> /entrypoint.sh && \
    echo 'exec nginx -g "daemon off;"' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
