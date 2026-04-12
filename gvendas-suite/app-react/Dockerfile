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

# Remove arquivos padrão do site
RUN rm -rf ./*

# A VERDADE ABSOLUTA: Removemos o default.conf padrão para evitar conflitos e erros de upstream
RUN rm /etc/nginx/conf.d/default.conf

# Copia o build do estágio anterior
COPY --from=build-stage /app/build .

# Copia o SEU arquivo de configuração como o único default.conf
COPY gvendas-suite/app-react/app_nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
