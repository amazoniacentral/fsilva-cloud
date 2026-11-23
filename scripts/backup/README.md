<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./scripts/backup
├── gdrive
│   ├── download-catalogo-bruto.sh
│   ├── download-treinamento.sh
│   └── envio-catalogo-compress.sh
├── r2
│   ├── backup-configs-encrypted.sh
│   ├── backup-db-encrypted.sh
│   ├── backup-volumes-encrypted.sh
│   ├── restore-configs-decrypted.sh
│   ├── restore-db-decrypted.sh
│   └── restore-volumes-decrypted.sh
└── README.md

3 directories, 10 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
#Dominio das Midias

MEDIA_DOMAIN=seu_dominio_media
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 23/11/2026_
<!-- END_ID:bloco_final -->
