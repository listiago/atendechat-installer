# Atendechat Auto Installer

Instalador automático do sistema Atendechat para Ubuntu 20.04+

## 📋 Pré-requisitos

- Ubuntu 20.04 ou superior
- Conexão com internet
- Permissões de sudo

## 🚀 Instalação Rápida

```bash
# 1. Clonar o instalador
git clone https://github.com/SEU_USERNAME/atendechat-installer.git
cd atendechat-installer

# 2. Tornar executável e rodar
chmod +x install.sh
./install.sh
```

## 📝 O que o instalador faz

### ✅ Verificações Automáticas
- Verifica se está rodando no Ubuntu 20.04+
- Detecta dependências já instaladas

### 🔧 Instalação de Dependências
- **Node.js 20.x** - Runtime JavaScript
- **Docker & Docker Compose** - Containers para bancos de dados
- **Git** - Controle de versão

### 📦 Configuração do Projeto
- Clona o repositório principal do Atendechat
- Cria arquivos `.env` com suas configurações
- Configura Postgres e Redis via Docker

### 🗄️ Banco de Dados
- Inicia containers Docker com Postgres e Redis
- Executa migrações e seeds automaticamente

### 👤 Criação de Usuário
- Cria usuário administrador com email e senha informados
- Configura permissões necessárias

### 🚀 Inicialização
- Inicia backend (porta configurada)
- Inicia frontend (porta configurada)

## ❓ Informações Solicitadas

Durante a instalação, o script irá perguntar:

1. **Email do usuário principal** - Email para login no sistema
2. **Senha do usuário principal** - Senha (mínimo 8 caracteres)
3. **Porta do backend** - Padrão: 8080
4. **Porta do frontend** - Padrão: 3000
5. **Domínio** - localhost para desenvolvimento
6. **Configurações do banco** - Nome, usuário e senha
7. **Configurações Redis** - Senha para Redis

## 🌐 Acesso Após Instalação

Após a instalação bem-sucedida:

- **Frontend**: http://localhost:3000 (ou domínio configurado)
- **Backend**: http://localhost:8080 (ou domínio configurado)

## 🛠️ Comandos Úteis

### Parar aplicações
```bash
pkill -f 'node\|npm'
```

### Reiniciar aplicações
```bash
cd atendechat
./restart.sh
```

### Ver logs do Docker
```bash
cd atendechat/backend
docker-compose -f docker-compose.databases.yml logs -f
```

### Acessar banco de dados
```bash
cd atendechat/backend
docker-compose -f docker-compose.databases.yml exec db_postgres psql -U atendechat -d atendechat_db
```

## 🔧 Solução de Problemas

### Erro de permissão no Docker
```bash
sudo usermod -aG docker $USER
# Reinicie a sessão ou execute: newgrp docker
```

### Porta já em uso
- Mude as portas durante a instalação
- Ou pare outros serviços usando as portas

### Falha na instalação de dependências
```bash
sudo apt update
sudo apt upgrade
```

## 📁 Estrutura Criada

```
atendechat-installer/
├── atendechat/           # Projeto principal clonado
│   ├── backend/         # API Node.js
│   ├── frontend/        # Interface React
│   └── docker/          # Configurações Docker
├── install.sh           # Script de instalação
└── README.md           # Esta documentação
```

## 🔒 Segurança

- Senhas são solicitadas de forma segura (não aparecem na tela)
- JWT secrets são gerados automaticamente
- Certifique-se de usar senhas fortes

## 📞 Suporte

Para problemas com a instalação:

1. Verifique os logs de erro
2. Confirme que todas as dependências foram instaladas
3. Verifique se as portas estão livres

## 📋 Checklist de Instalação

- [ ] Ubuntu 20.04+ instalado
- [ ] Conexão com internet funcionando
- [ ] Permissões de sudo disponíveis
- [ ] Instalador clonado
- [ ] Script executado com sucesso
- [ ] Aplicações acessíveis via navegador

---

**Versão**: 1.0.0
**Compatível com**: Ubuntu 20.04+
**Projeto**: Atendechat WhatsApp
