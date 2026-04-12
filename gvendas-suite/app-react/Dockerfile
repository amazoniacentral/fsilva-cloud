# Estágio 1: Build da aplicação
FROM node:20-alpine AS build-stage
WORKDIR /app

# Copia dependências a partir da raiz do contexto
COPY repos/gvendas/package*.json ./
RUN npm install

# Copia o código da aplicação
COPY repos/gvendas/ .
RUN npm run build

# Estágio 2: Nginx
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html

# Remove arquivos padrão
RUN rm -rf ./*

# Copia o build do estágio anterior
COPY --from=build-stage /app/build .

# A VERDADE ABSOLUTA: O default.conf está na pasta do Dockerfile, 
# então o caminho parte da raiz conforme definido no docker-compose.
COPY gvendas-suite/app-react/app_nginx.conf /etc/nginx/conf.d/app_nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
