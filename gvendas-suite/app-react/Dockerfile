# Estágio 1: Build da aplicação
FROM node:20-alpine AS build-stage
# Define um único diretório para tudo
WORKDIR /app

# 1. Copia dependências primeiro (aproveita cache)
COPY repos/gvendas/package*.json ./
RUN npm install

# 2. Copia todo o código para o MESMO diretório (/app)
COPY repos/gvendas/ .

# 3. Copia o .env (garantindo que o caminho do host esteja correto)
COPY gvendas-suite/app-react/.env .env

# 4. Agora o react-scripts será encontrado pois node_modules está aqui
RUN npm run build

# Estágio 2: Nginx
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html

RUN rm -rf ./*
RUN rm -f /etc/nginx/conf.d/default.conf

# Copia o build do estágio anterior (da pasta /app)
COPY --from=build-stage /app/build .

# Copia sua configuração de Nginx
COPY gvendas-suite/app-react/app_nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
