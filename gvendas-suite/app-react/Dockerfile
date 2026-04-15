# Estágio 1: Build da aplicação
FROM node:20-alpine AS build-stage
WORKDIR /app

# 1. Copia dependências
COPY repos/gvendas/package*.json ./
RUN npm install

# 2. Copia todo o código para /app
COPY repos/gvendas/ .

# 3. Copia o .env
COPY gvendas-suite/app-react/.env .env

# 4. Executa o build e verifica se a pasta foi criada
# Adicionamos o "ls" aqui para garantir visualmente no log que os arquivos existem
RUN npm run build && ls -la /app/build

# Estágio 2: Nginx
FROM nginx:stable-alpine

# Limpa diretórios
RUN rm -rf /usr/share/nginx/html/*
RUN rm -f /etc/nginx/conf.d/default.conf

# 5. Copia os arquivos do estágio de build
# Usamos o caminho absoluto /app/build
COPY --from=build-stage /app/build /usr/share/nginx/html

# 6. Copia a configuração do Nginx
COPY gvendas-suite/app-react/app_nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
