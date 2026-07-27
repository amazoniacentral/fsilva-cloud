# Estágio 1: Build
FROM node:20-alpine AS build-stage
WORKDIR /app
COPY repos/gvendas/package*.json ./
RUN npm install
COPY repos/gvendas/ .
RUN export VERSION=$(node -p "require('./package.json').version") && \
    echo "Construindo versão: $VERSION" && \
    REACT_APP_VERSION=$VERSION GENERATE_SOURCEMAP=false npm run build

# Estágio 2: Nginx (Runtime)
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html

# Copia do build
COPY --from=build-stage /app/build .

# Configurações do Nginx
COPY apps/auth-nginx.conf /etc/nginx/auth-nginx.conf
COPY apps/gvendas/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
