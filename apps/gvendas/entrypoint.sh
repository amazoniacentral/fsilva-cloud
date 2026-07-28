#!/bin/sh

# Cria o arquivo config.json com os valores das variáveis de ambiente atuais
cat <<EOF > /usr/share/nginx/app/env-config.js
window._env_ = {
  "API_DOMAIN": "${API_DOMAIN}",
  "META_APP_ID": "${META_APP_ID}",
  "CONFIG_ID": "${CONFIG_ID}"
};
EOF

cp -r /usr/share/nginx/html/* /usr/share/nginx/app/

# Inicia o Nginx
exec nginx -g 'daemon off;'


