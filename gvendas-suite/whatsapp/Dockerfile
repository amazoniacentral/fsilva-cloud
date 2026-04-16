FROM node:20-slim

WORKDIR /code

# Copia apenas os arquivos de pacotes primeiro (otimiza o cache)
COPY repos/push/package*.json ./

# Instala as dependências do Node (apenas uma vez no build)
RUN npm install

# Copia o resto dos arquivos do seu sistema
COPY repos/push/ .

# Comando para iniciar o app
CMD ["npm", "start"]
