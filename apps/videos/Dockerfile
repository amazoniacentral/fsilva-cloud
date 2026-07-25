# Usa uma versão estável e leve do Node.js baseada em Debian
FROM node:18-bullseye-slim

# Instala o FFmpeg e dependências necessárias
# O rm -rf limpa os arquivos temporários, deixando a imagem mais leve
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
