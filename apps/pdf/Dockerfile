FROM node:22-slim

# Dependências do Chromium (Puppeteer)
RUN apt-get update && apt-get install -y \
  chromium \
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
  ca-certificates \
  --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# melhor cache do npm
COPY package.json package-lock.json* ./

RUN npm install

COPY . .

# MUITO IMPORTANTE pro Puppeteer
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

EXPOSE 3000

CMD ["node", "src/server.js"]