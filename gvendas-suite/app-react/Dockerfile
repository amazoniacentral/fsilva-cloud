# Estágio 1: Build da aplicação
FROM node:20-alpine AS build-stage
WORKDIR /app

# 1. Copia dependências primeiro (aproveita cache)
COPY repos/gvendas/package*.json ./
RUN npm install

# 2. Copia todo o código da aplicação
WORKDIR /code
COPY repos/gvendas/ .

# 3. A VERDADE: Copia o .env POR ÚLTIMO para garantir que nada o sobrescreva
COPY gvendas-suite/app-react/.env .env

# 4. Agora sim, roda o build com o .env correto injetado
RUN npm run build

# Estágio 2: Nginx
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html

RUN rm -rf ./*
RUN rm /etc/nginx/conf.d/default.conf

# Copia o build do estágio anterior
COPY --from=build-stage /code/build .

# Copia sua configuração de Nginx
COPY gvendas-suite/app-react/app_nginx.conf /etc/nginx/conf.d/default.conf

RUN rm -rf /code/build

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
