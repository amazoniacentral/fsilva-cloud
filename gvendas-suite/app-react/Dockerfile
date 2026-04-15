# Estágio 1: Build da aplicação
FROM node:20-alpine AS build-stage
# Define o diretório de trabalho
WORKDIR /app

# 1. Copia dependências primeiro (aproveita cache)
# Ajustado para o caminho relativo correto baseado no comando de cópia posterior
COPY repos/gvendas/package*.json ./
RUN npm install

# 2. Copia todo o código da aplicação
COPY repos/gvendas/ .

# 3. Copia o arquivo de ambiente
COPY gvendas-suite/app-react/.env .env

# 4. Executa o build
# O react-scripts gera por padrão a pasta /app/build
RUN npm run build

# Estágio 2: Nginx
FROM nginx:stable-alpine
WORKDIR /usr/share/nginx/html

# Limpa o diretório padrão do Nginx
RUN rm -rf ./*
RUN rm -f /etc/nginx/conf.d/default.conf

# 5. Copia o build do estágio anterior
# Verifica se a pasta build realmente existe em /app/build
COPY --from=build-stage /app/build /usr/share/nginx/html

# 6. Copia a configuração do Nginx
COPY gvendas-suite/app-react/app_nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
