# Estágio 1: Build da aplicação
FROM node:20-alpine AS build-stage
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Estágio 2: Nginx
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html

# Remove arquivos padrão
RUN rm -rf ./*

# Copia o build do estágio anterior
COPY --from=build-stage /app/dist .

# Copia sua configuração personalizada do Nginx para dentro da imagem
COPY default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
