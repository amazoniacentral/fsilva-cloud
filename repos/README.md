# Submodules

Adicionar *[submodule](./)* no projeto
- Instalação de Módulos
```bash
git submodule add git@github.com:amazoniacentral/docker-vps.git repos/docker-vps
```

- Remoção de Módulos
1. Remova a pasta do submódulo do índice do git
```bash
git rm -f scripts/docker-vps
```

2. Remova a pasta física do disco
```bash
rm -rf .git/modules/scripts/docker-vps
```

---
**Desenvolvido por Francisco Silva (FSilva) — 2026**
