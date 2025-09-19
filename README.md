# Atendechat Auto Installer

Instalador automático completo do sistema Atendechat para Ubuntu 20.04+ - **Versão 1.2.1**

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

## ⚡ Início Rápido (Após Instalação)

### **Opção 1: Com PM2 (Recomendado)**
```bash
# Iniciar tudo automaticamente com PM2
./start.sh
```
**Vantagens:** Processos persistem após fechar terminal, monitoramento automático.

### **Opção 2: Inicialização Simples**
```bash
# Iniciar sem PM2 (processos param ao fechar terminal)
./start-simple.sh
```
**Vantagens:** Mais rápido, sem dependências adicionais.

**Ambos comandos iniciam:** containers Docker + backend + frontend + migrations + seeds

## ⚡ PM2 - Gerenciamento Avançado de Processos

O sistema utiliza **PM2** para gerenciamento profissional de processos:

### ✅ Vantagens do PM2:
- **Persistência**: Processos continuam rodando após fechar terminal
- **Monitoramento**: CPU, memória, logs em tempo real
- **Auto-restart**: Reinicia automaticamente em caso de falha
- **Cluster**: Suporte a múltiplas instâncias
- **Logs centralizados**: Fácil debug e troubleshooting

### 🎮 Comandos PM2 Úteis:
```bash
# Ver status das aplicações
pm2 status

# Ver logs em tempo real
pm2 logs

# Monitor interativo
pm2 monit

# Reiniciar aplicação específica
pm2 restart atendechat-backend

# Parar todas as aplicações
pm2 stop all

# Interface web (opcional)
pm2 plus
```

## ✨ O que foi corrigido na versão 1.2.1

### ✅ Correções Implementadas
- **URLs do GitHub**: Repositórios públicos (sem necessidade de token)
- **Docker Compose**: Configuração 100% compatível com Ubuntu 20.04
- **OpenSSL Error**: Correção automática e permanente no package.json
- **Credenciais do Banco**: Configuração automática com senhas corretas
- **Build do Backend**: Compilação TypeScript antes das migrações
- **package.json Frontend**: Correção automática dos scripts start e build
- **Tratamento de erros**: Melhor detecção e correção de problemas
- **Verificação final**: Testa se tudo está funcionando
- **Docker Daemon**: Correção automática para iniciar serviço Docker
- **Comandos Docker**: Adição de sudo para compatibilidade

### 🔧 Melhorias da Versão 1.2.1
- ✅ **Instalação 100% automática** - Não requer intervenção manual
- ✅ **Correção automática do frontend** - OpenSSL resolvido permanentemente
- ✅ **Build automático do backend** - TypeScript compilado corretamente
- ✅ **Configuração correta do banco** - Credenciais alinhadas entre .env e containers
- ✅ **Mensagens de erro claras** - Diagnóstico preciso de problemas
- ✅ **Recuperação automática de falhas** - Tenta corrigir problemas automaticamente
- ✅ **Suporte completo a Ubuntu 20.04+** - Testado e validado
- ✅ **Persistência de dados** - Dados mantidos entre reinicializações
- ✅ **Docker daemon automático** - Serviço iniciado automaticamente quando necessário

### 🗄️ Persistência de Dados (NOVO)

A partir da versão 1.2.1, o sistema agora mantém **todos os dados persistentes** entre reinicializações:

#### ✅ O que é mantido:
- **Dados do PostgreSQL**: Usuários, empresas, tickets, mensagens
- **Dados do Redis**: Sessões, cache, configurações temporárias
- **Configurações**: Usuários administradores, empresas criadas
- **Histórico**: Todos os dados inseridos durante desenvolvimento/testes

#### 🔄 Como funciona:
- **Volumes Docker**: PostgreSQL e Redis usam volumes nomeados persistentes
- **Verificação inteligente**: Sistema detecta se banco já foi configurado
- **Migrações seletivas**: Só executa migrações na primeira instalação
- **Seeds condicionais**: Seeds só rodam se banco estiver vazio

#### 📊 Benefícios para desenvolvimento:
- ✅ **Reinicializações rápidas**: Não perde dados ao reiniciar máquina
- ✅ **Testes consistentes**: Dados permanecem entre sessões
- ✅ **Desenvolvimento contínuo**: Trabalhe sem perder progresso
- ✅ **Configuração uma vez**: Setup inicial persiste indefinidamente

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

### `start.sh` - Iniciar sistema com PM2 ⭐ **NOVO**
```bash
./start.sh
```
Inicia automaticamente: containers Docker + backend + frontend + PM2 (persistência)

### `start-simple.sh` - Iniciar sistema simples ⭐ **NOVO**
```bash
./start-simple.sh
```
Inicia sem PM2: containers Docker + backend + frontend (processos param ao fechar terminal)

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

### `create-admin.sh` - Criar usuário administrador ⭐ **NOVO**
```bash
./create-admin.sh
```
Cria usuário administrador manualmente se necessário

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

## 🛠️ Scripts de Gerenciamento (Desenvolvimento)

### `install.sh` - Instalador completo
```bash
./install.sh
```
Instala todo o sistema automaticamente (uma vez)

### `start.sh` - Iniciar sistema automaticamente ⭐
```bash
./start.sh
```
Inicia automaticamente: containers Docker + backend + frontend + migrations + seeds

### `stop.sh` - Parar sistema completamente ⭐
```bash
./stop.sh
```
Para todos os processos Node.js e containers Docker corretamente

### `status.sh` - Verificar status do sistema ⭐
```bash
./status.sh
```
Verifica status completo: Docker, containers, processos, aplicações e conectividade

### `restart.sh` - Reiniciar aplicações
```bash
./restart.sh
```

### `test.sh` - Verificar conectividade
```bash
./test.sh
```

### `create-admin.sh` - Criar usuário administrador
```bash
./create-admin.sh
```
Cria usuário administrador manualmente se necessário

---

**Versão**: 1.2.1 (Completa)
**Compatível com**: Ubuntu 20.04+
**Repositório**: https://github.com/listiago/atendechat
**Instalador**: https://github.com/listiago/atendechat-installer
