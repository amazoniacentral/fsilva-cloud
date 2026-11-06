# Usa uma versão moderna e estável do Node.js baseada no Debian atualizado
FROM node:20-slim

# Instala o FFmpeg e dependências necessárias de forma limpa
RUN apt-get update && apt-get install -y \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Cria o diretório de trabalho dentro do contêiner
WORKDIR /app

# Copia os arquivos de configuração do Node para instalar dependências
# Isso garante o cache eficiente das camadas
COPY package*.json ./

# Instala apenas as dependências de produção
RUN npm install --only=production

# Copia o restante do código da aplicação
COPY ./src ./src
COPY ./public ./public

# Cria a pasta onde os vídeos serão processados e salvos
RUN mkdir -p /var/www/videos /app/uploads

# Expõe a porta que o Node.js está usando
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["node", "src/server.js"]
