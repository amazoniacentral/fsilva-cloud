#!/bin/sh

# Cria o arquivo config.json com os valores das variáveis de ambiente atuais
cat <<EOF > /usr/share/nginx/html/env-config.js
window._env_ = {
  "API_DOMAIN": "${API_DOMAIN}",
  "META_APP_ID": "${META_APP_ID}",
  "CONFIG_ID": "${CONFIG_ID}"
};
EOF

# Inicia o Nginx
exec nginx -g 'daemon off;'
