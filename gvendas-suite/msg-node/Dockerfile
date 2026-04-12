FROM node:20-slim

WORKDIR /usr/src/app

# Copia apenas os arquivos de pacotes primeiro (otimiza o cache)
COPY package*.json ./

# Instala as dependências do Node (apenas uma vez no build)
RUN npm install

# Copia o resto dos arquivos do seu sistema
COPY . .

# Comando para iniciar o app
CMD ["npm", "start"]
