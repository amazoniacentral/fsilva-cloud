<!-- START_ID:cabecalho -->
# FSilva Cloud
*Infraestrutura de Alta Disponibilidade e Orquestração de Containers*

_Uma estrutura híbrida para garantir que seus aplicativos Docker estejam acessíveis de forma segura e eficiente, adaptando-se a diferentes cenários de rede._
<!-- END_ID:cabecalho -->

<!-- START_ID:bloco_estrutura -->
```bash
./scripts
├── deploy
│   ├── README.md
│   ├── dev_update.sh
│   ├── prod_update.sh
│   └── setup.sh
├── documentacao
│   ├── README.md
│   ├── atualizar_example_readme_env.sh
│   ├── blocos.sh
│   ├── cabecalho.sh
│   ├── estrutura.sh
│   ├── rodape.sh
│   └── setup.sh
├── .env.example
├── README.md
├── alias.sh
├── backup_db.sh
├── backup_rclone.sh
├── containers.sh
├── crontab.sh
├── database.sh
├── db_baixar.sh
├── gitmodules.sh
├── haskey.sh
├── install.sh
├── limpar_traefik.sh
├── otimizar_rede.sh
├── reset.sh
├── setup_reclone.sh
├── status.sh
└── sync_rclone.sh

3 directories, 29 files
```
<!-- END_ID:bloco_estrutura -->


### Configurações de variáveis .env
```.env <!-- ID: .env.example -->
# Configurações para o Rsync (Transferência Remota)
# RSYNC_ORIGEM_USER=seu_usuario_remoto
# RSYNC_ORIGEM_IP=123.123.123.123
# RSYNC_ORIGEM_PATH=/caminho/no/servidor/remoto/backup.backup

# Configurações de Paths Locais (Opcional, conforme scripts anteriores)
# DESTINO_PATH_BANCO=/caminho/local/do/backup.backup
```

<!-- START_ID:bloco_final -->
---
**Desenvolvido por Francisco Silva (FSilva)**

_Atualizado em: 15/05/2026_
<!-- END_ID:bloco_final -->
