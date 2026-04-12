FROM node:20-slim

WORKDIR /usr/src/app

# Copia apenas os arquivos de pacotes primeiro (otimiza o cache)
COPY repos/sgn/package*.json ./

# Instala as dependências do Node (apenas uma vez no build)
RUN npm install

# Copia o resto dos arquivos do seu sistema
COPY repos/sgn/ .

# Comando para iniciar o app
CMD ["npm", "start"]
