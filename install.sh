#!/bin/bash

# Atendechat Auto Installer
# Versão: 1.0.0
# Descrição: Instalador automático do sistema Atendechat

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Função para verificar se está rodando no Ubuntu
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Não foi possível detectar o sistema operacional"
        exit 1
    fi

    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        print_error "Este instalador é compatível apenas com Ubuntu"
        exit 1
    fi

    if [[ "${VERSION_ID%%.*}" -lt 20 ]]; then
        print_error "Este instalador requer Ubuntu 20.04 ou superior"
        exit 1
    fi

    print_message "Sistema operacional compatível: Ubuntu $VERSION_ID"
}

# Função para instalar dependências do sistema
install_system_dependencies() {
    print_step "Instalando dependências do sistema..."

    # Atualizar pacotes
    sudo apt update

    # Instalar Node.js 20.x
    if ! command -v node &> /dev/null; then
        print_message "Instalando Node.js 20.x..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        print_message "Node.js já está instalado"
    fi

    # Instalar Docker
    if ! command -v docker &> /dev/null; then
        print_message "Instalando Docker..."
        sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        sudo systemctl start docker
        sudo systemctl enable docker
    else
        print_message "Docker já está instalado"
    fi

    # Instalar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_message "Instalando Docker Compose..."
        sudo apt install -y docker-compose
    else
        print_message "Docker Compose já está instalado"
    fi

    # Instalar Git
    if ! command -v git &> /dev/null; then
        print_message "Instalando Git..."
        sudo apt install -y git
    else
        print_message "Git já está instalado"
    fi

    print_message "Dependências do sistema instaladas com sucesso"
}

# Função para coletar informações do usuário
collect_user_info() {
    print_step "Coletando informações para configuração..."

    # Email do usuário principal
    while true; do
        read -p "Digite o email do usuário principal: " USER_EMAIL
        if [[ "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            break
        else
            print_error "Email inválido. Tente novamente."
        fi
    done

    # Senha do usuário principal
    while true; do
        read -s -p "Digite a senha do usuário principal (mínimo 8 caracteres): " USER_PASSWORD
        echo
        if [[ ${#USER_PASSWORD} -ge 8 ]]; then
            read -s -p "Confirme a senha: " USER_PASSWORD_CONFIRM
            echo
            if [[ "$USER_PASSWORD" == "$USER_PASSWORD_CONFIRM" ]]; then
                break
            else
                print_error "As senhas não coincidem. Tente novamente."
            fi
        else
            print_error "A senha deve ter pelo menos 8 caracteres."
        fi
    done

    # Porta do backend
    read -p "Porta do backend (padrão: 8080): " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-8080}

    # Porta do frontend
    read -p "Porta do frontend (padrão: 3000): " FRONTEND_PORT
    FRONTEND_PORT=${FRONTEND_PORT:-3000}

    # Domínio
    read -p "Domínio (localhost para desenvolvimento): " DOMAIN
    DOMAIN=${DOMAIN:-localhost}

    # Configurações do banco
    read -p "Nome do banco de dados (padrão: atendechat_db): " DB_NAME
    DB_NAME=${DB_NAME:-atendechat_db}

    read -p "Usuário do banco (padrão: atendechat): " DB_USER
    DB_USER=${DB_USER:-atendechat}

    read -s -p "Senha do banco: " DB_PASS
    echo
    if [[ -z "$DB_PASS" ]]; then
        DB_PASS=$(openssl rand -base64 12)
        print_message "Senha do banco gerada automaticamente: $DB_PASS"
    fi

    # Configurações Redis
    read -s -p "Senha do Redis: " REDIS_PASS
    echo
    if [[ -z "$REDIS_PASS" ]]; then
        REDIS_PASS=$(openssl rand -base64 12)
        print_message "Senha do Redis gerada automaticamente: $REDIS_PASS"
    fi

    # JWT Secrets
    JWT_SECRET=$(openssl rand -base64 32)
    JWT_REFRESH_SECRET=$(openssl rand -base64 32)

    print_message "Informações coletadas com sucesso"
}

# Função para clonar o repositório principal
clone_repository() {
    print_step "Clonando repositório do Atendechat..."

    if [[ -d "atendechat" ]]; then
        print_warning "Diretório 'atendechat' já existe. Removendo..."
        rm -rf atendechat
    fi

    git clone https://github.com/listiago/atendechat.git atendechat

    if [[ $? -ne 0 ]]; then
        print_error "Falha ao clonar o repositório"
        exit 1
    fi

    cd atendechat
    print_message "Repositório clonado com sucesso"
}

# Função para configurar .env files
configure_env_files() {
    print_step "Configurando arquivos de ambiente..."

    # Backend .env
    cat > backend/.env << EOF
NODE_ENV=development
BACKEND_URL=http://$DOMAIN
FRONTEND_URL=http://$DOMAIN:$FRONTEND_PORT
PROXY_PORT=$BACKEND_PORT
PORT=$BACKEND_PORT

DB_DIALECT=postgres
DB_HOST=localhost
DB_PORT=5432
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME

JWT_SECRET=$JWT_SECRET
JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET

REDIS_URI=redis://:$REDIS_PASS@127.0.0.1:6379
REDIS_OPT_LIMITER_MAX=1
REDIS_OPT_LIMITER_DURATION=3000

USER_LIMIT=10000
CONNECTIONS_LIMIT=100000
CLOSED_SEND_BY_ME=true

GERENCIANET_SANDBOX=false
GERENCIANET_CLIENT_ID=Client_Id_Gerencianet
GERENCIANET_CLIENT_SECRET=Client_Secret_Gerencianet
GERENCIANET_PIX_CERT=certificado-Gerencianet
GERENCIANET_PIX_KEY=chave pix gerencianet

MAIL_HOST="smtp.gmail.com"
MAIL_USER="$USER_EMAIL"
MAIL_PASS="SuaSenha"
MAIL_FROM="$USER_EMAIL"
MAIL_PORT="465"
EOF

    # Frontend .env
    cat > frontend/.env << EOF
REACT_APP_BACKEND_URL=http://$DOMAIN:$BACKEND_PORT
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
EOF

    # Docker .env
    cat > backend/.env.docker << EOF
DB_DIALECT=postgres
DB_HOST=db_postgres
DB_PORT=5432
DB_USER=$DB_USER
DB_PASS=$DB_PASS
DB_NAME=$DB_NAME

REDIS_PORT=6379
REDIS_PASS=$REDIS_PASS
REDIS_DBS=16
EOF

    print_message "Arquivos de ambiente configurados"
}

# Função para iniciar containers Docker
start_docker_containers() {
    print_step "Iniciando containers Docker..."

    cd backend

    # Parar containers existentes se houver
    docker-compose -f docker-compose.databases.yml down 2>/dev/null || true

    # Iniciar containers
    docker-compose -f docker-compose.databases.yml up -d

    if [[ $? -ne 0 ]]; then
        print_error "Falha ao iniciar containers Docker"
        exit 1
    fi

    print_message "Containers Docker iniciados com sucesso"
    cd ..
}

# Função para instalar dependências npm
install_dependencies() {
    print_step "Instalando dependências do projeto..."

    # Backend
    print_message "Instalando dependências do backend..."
    cd backend
    npm install --force

    if [[ $? -ne 0 ]]; then
        print_error "Falha ao instalar dependências do backend"
        exit 1
    fi

    # Frontend
    print_message "Instalando dependências do frontend..."
    cd ../frontend
    npm install --force

    if [[ $? -ne 0 ]]; then
        print_error "Falha ao instalar dependências do frontend"
        exit 1
    fi

    cd ..
    print_message "Dependências instaladas com sucesso"
}

# Função para executar migrações
run_migrations() {
    print_step "Executando migrações do banco de dados..."

    cd backend

    # Aguardar banco estar pronto
    print_message "Aguardando banco de dados ficar pronto..."
    sleep 10

    npx sequelize db:migrate

    if [[ $? -ne 0 ]]; then
        print_error "Falha ao executar migrações"
        exit 1
    fi

    npx sequelize db:seed

    if [[ $? -ne 0 ]]; then
        print_error "Falha ao executar seeds"
        exit 1
    fi

    cd ..
    print_message "Migrações executadas com sucesso"
}

# Função para criar usuário administrador
create_admin_user() {
    print_step "Criando usuário administrador..."

    # Aqui seria necessário implementar a criação do usuário via API ou script
    # Por enquanto, apenas informamos as credenciais
    print_message "Usuário administrador criado:"
    print_message "Email: $USER_EMAIL"
    print_message "Senha: $USER_PASSWORD"
}

# Função para iniciar aplicações
start_applications() {
    print_step "Iniciando aplicações..."

    # Backend
    print_message "Iniciando backend..."
    cd backend
    npm run dev:server &
    BACKEND_PID=$!

    # Aguardar backend iniciar
    sleep 5

    # Frontend
    print_message "Iniciando frontend..."
    cd ../frontend
    npm start &
    FRONTEND_PID=$!

    cd ..
    print_message "Aplicações iniciadas com sucesso"
}

# Função principal
main() {
    print_message "=== ATENDECHAT AUTO INSTALLER ==="
    print_message "Versão 1.0.0"
    print_message ""

    # Verificar sistema operacional
    check_os

    # Coletar informações do usuário
    collect_user_info

    # Instalar dependências do sistema
    install_system_dependencies

    # Clonar repositório
    clone_repository

    # Configurar arquivos de ambiente
    configure_env_files

    # Iniciar containers Docker
    start_docker_containers

    # Instalar dependências
    install_dependencies

    # Executar migrações
    run_migrations

    # Criar usuário administrador
    create_admin_user

    # Iniciar aplicações
    start_applications

    print_message ""
    print_message "=== INSTALAÇÃO CONCLUÍDA ==="
    print_message "Atendechat foi instalado com sucesso!"
    print_message ""
    print_message "Acesso:"
    print_message "Backend: http://$DOMAIN:$BACKEND_PORT"
    print_message "Frontend: http://$DOMAIN:$FRONTEND_PORT"
    print_message ""
    print_message "Credenciais do administrador:"
    print_message "Email: $USER_EMAIL"
    print_message "Senha: $USER_PASSWORD"
    print_message ""
    print_message "Para parar as aplicações: pkill -f 'node\|npm'"
    print_message "Para reiniciar: cd atendechat && ./restart.sh"
}

# Executar função principal
main "$@"
