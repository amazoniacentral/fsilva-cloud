FROM node:22-slim

# Dependências necessárias para Chromium + Puppeteer
RUN apt-get update && apt-get install -y \
  ca-certificates \
  fonts-liberation \
  libnss3 \
  libx11-xcb1 \
  libxcomposite1 \
  libxdamage1 \
  libxrandr2 \
  libasound2 \
  libatk1.0-0 \
  libatk-bridge2.0-0 \
  libgtk-3-0 \
  libgbm1 \
  libdrm2 \
  libxshmfence1 \
  libpangocairo-1.0-0 \
  libpango-1.0-0 \
  libatspi2.0-0 \
  libxcursor1 \
  libxfixes3 \
  libxi6 \
  libxrender1 \
  libxext6 \
  libglib2.0-0 \
  libdbus-1-3 \
  tar \
  unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /home/node

# cache melhor do npm
COPY package.json package-lock.json* ./

RUN npm install

COPY ./src ./src

# ✅ MODO ISOLADO (Puppeteer gerencia Chromium)
ENV PUPPETEER_SKIP_DOWNLOAD=false

EXPOSE 3000

CMD ["node", "src/server.js"]