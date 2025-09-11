# Atendechat Auto Installer

Instalador automático do sistema Atendechat para Ubuntu 20.04+ - **Versão Corrigida 1.1.0**

## 📋 Pré-requisitos

- Ubuntu 20.04 ou superior
- Conexão com internet
- Permissões de sudo

## 🚀 Instalação Rápida

```bash
# 1. Clonar o instalador
git clone https://github.com/listiago/atendechat-installer.git
cd atendechat-installer

# 2. Dar permissões e executar
chmod +x *.sh
./install.sh
```

## ✨ O que foi corrigido na versão 1.1.0

### ✅ Correções Implementadas
- **URLs do GitHub**: Agora usa repositórios públicos (sem necessidade de token)
- **Docker Compose**: Configuração compatível com Ubuntu 20.04
- **OpenSSL Error**: Correção automática para Node.js v20+
- **Banco de dados**: Configuração automática de PostgreSQL e Redis
- **Tratamento de erros**: Melhor detecção e correção de problemas
- **Verificação final**: Testa se tudo está funcionando

### 🔧 Melhorias
- Instalação mais rápida e confiável
- Mensagens de erro mais claras
- Recuperação automática de falhas
- Suporte completo a Ubuntu 20.04+

## 📝 O que o instalador faz

### ✅ Verificações Automáticas
- Verifica se está rodando no Ubuntu 20.04+
- Detecta dependências já instaladas
- Corrige problemas automaticamente

### 🔧 Instalação de Dependências
- **Node.js 20.x** - Runtime JavaScript
- **Docker & Docker Compose** - Containers para bancos de dados
- **Git** - Controle de versão

### 📦 Configuração do Projeto
- Clona o repositório público do Atendechat
- Cria arquivos `.env` com suas configurações
- Configura PostgreSQL e Redis via Docker

### 🗄️ Banco de Dados
- Inicia containers com PostgreSQL e Redis
- Executa migrações e seeds automaticamente
- Cria usuário administrador

### 👤 Criação de Usuário
- Cria usuário administrador com email e senha informados
- Configura permissões necessárias

### 🚀 Inicialização
- Inicia backend (porta configurada)
- Inicia frontend (porta configurada)
- Corrige automaticamente erros OpenSSL

## ❓ Informações Solicitadas

Durante a instalação, responda:

1. **Email do usuário principal** - Email para login no sistema
2. **Senha do usuário principal** - Senha (mínimo 8 caracteres)
3. **Porta do backend** - Padrão: 8080
4. **Porta do frontend** - Padrão: 3000
5. **Domínio** - `localhost` para desenvolvimento
6. **Configurações do banco** - Nome, usuário e senha

## 🌐 Acesso Após Instalação

Após instalação bem-sucedida:
- **Frontend**: http://localhost:3000
- **Backend**: http://localhost:8080

## 🛠️ Scripts Disponíveis

### `install.sh` - Instalador principal
```bash
./install.sh
```

### `restart.sh` - Reiniciar aplicações
```bash
./restart.sh
```

### `stop.sh` - Parar aplicações
```bash
./stop.sh
```

### `test.sh` - Verificar se está funcionando
```bash
./test.sh
```

## 🔧 Solução de Problemas

### Docker não inicia
```bash
sudo systemctl start docker
sudo systemctl enable docker
```

### Erro de permissão
```bash
sudo usermod -aG docker $USER
newgrp docker
```

### Aplicação não responde
```bash
# Verificar processos
ps aux | grep node

# Verificar portas
netstat -tlnp | grep :3000
netstat -tlnp | grep :8080
```

## 📁 Estrutura Criada

```
atendechat-installer/
├── atendechat/           # Projeto principal
│   ├── backend/         # API Node.js
│   ├── frontend/        # Interface React
│   └── docker/          # Containers
├── install.sh           # Script de instalação
├── restart.sh           # Script de restart
├── stop.sh             # Script de stop
├── test.sh             # Script de teste
└── README.md           # Esta documentação
```

## 🔒 Segurança

- ✅ Repositórios públicos (sem tokens necessários)
- ✅ Senhas geradas automaticamente quando não informadas
- ✅ JWT secrets gerados automaticamente
- ✅ Containers isolados

## 📞 Suporte

Para problemas:

1. Execute `./test.sh` para diagnóstico
2. Verifique logs: `docker-compose -f backend/docker-compose.databases.yml logs`
3. Reinicie: `./restart.sh`

## 📋 Checklist de Instalação

- [ ] Ubuntu 20.04+ instalado
- [ ] Conectado à internet
- [ ] Permissões de sudo OK
- [ ] Repositório clonado
- [ ] Scripts com permissão de execução
- [ ] Instalador executado com sucesso
- [ ] Aplicações acessíveis no navegador

## 🎉 Resultado Final

Após instalação bem-sucedida, você terá:
- ✅ Sistema Atendechat completamente funcional
- ✅ PostgreSQL e Redis rodando em containers
- ✅ Backend e Frontend inicializados
- ✅ Usuário administrador criado
- ✅ Acesso via navegador

---

**Versão**: 1.1.0 (Corrigida)
**Compatível com**: Ubuntu 20.04+
**Repositório**: https://github.com/listiago/atendechat
**Instalador**: https://github.com/listiago/atendechat-installer
