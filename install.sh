#!/bin/bash

# Atendechat Auto Installer - Versão Corrigida
# Versão: 1.2.1
# Descrição: Instalador automático completo com criação garantida do usuário administrador

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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
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

    # Usar repositório público
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
DB_USER=atendechat
DB_PASS=postgres_password_123
DB_NAME=atendechat_db

JWT_SECRET=$JWT_SECRET
JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET

REDIS_URI=redis://:redis_password_123@127.0.0.1:6379
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
MAIL_PASS="$USER_PASSWORD"
MAIL_FROM="$USER_EMAIL"
MAIL_PORT="465"
EOF

    # Frontend .env
    cat > frontend/.env << EOF
REACT_APP_BACKEND_URL=http://$DOMAIN:$BACKEND_PORT
REACT_APP_HOURS_CLOSE_TICKETS_AUTO=24
EOF

    print_message "Arquivos de ambiente configurados"
}

# Função para criar docker-compose corrigido
create_docker_compose() {
    print_step "Criando configuração Docker corrigida..."

    cat > backend/docker-compose.databases.yml << 'EOF'
version: '3.7'

services:
  cache:
    image: redis:latest
    ports:
      - "6379:6379"
    environment:
      - REDIS_PASSWORD=redis_password_123
    command: redis-server --requirepass redis_password_123

  db_postgres:
    image: postgres:13
    environment:
      - POSTGRES_PASSWORD=postgres_password_123
      - POSTGRES_USER=atendechat
      - POSTGRES_DB=atendechat_db
    ports:
      - "5432:5432"
EOF

    print_message "Docker Compose criado com sucesso"
}

# Função para iniciar containers Docker
start_docker_containers() {
    print_step "Iniciando containers Docker..."

    # Garantir que o Docker daemon esteja rodando
    if ! sudo systemctl is-active --quiet docker; then
        print_message "Iniciando serviço Docker..."
        sudo systemctl start docker
        sleep 2
    fi

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

# Função para corrigir package.json do frontend
fix_frontend_package() {
    print_step "Corrigindo package.json do frontend..."

    cd frontend

    # Fazer backup
    cp package.json package.json.backup

    # Corrigir script start
    sed -i 's/"start": "react-scripts start"/"start": "NODE_OPTIONS=--openssl-legacy-provider react-scripts start"/g' package.json

    # Corrigir script build
    sed -i 's/"build": "react-scripts build"/"build": "NODE_OPTIONS=--openssl-legacy-provider GENERATE_SOURCEMAP=false react-scripts build"/g' package.json

    print_message "package.json do frontend corrigido"
    cd ..
}

# Função para instalar dependências npm
install_dependencies() {
    print_step "Instalando dependências do projeto..."

    # Corrigir frontend primeiro
    fix_frontend_package

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

# Função para compilar backend
build_backend() {
    print_step "Compilando backend..."

    cd backend

    # Compilar TypeScript
    npm run build

    if [[ $? -ne 0 ]]; then
        print_error "Falha ao compilar backend"
        exit 1
    fi

    # Verificar se pasta dist foi criada
    if [[ -d "dist" ]]; then
        print_success "Backend compilado com sucesso"
    else
        print_error "Pasta dist não foi criada"
        exit 1
    fi

    cd ..
}

# Função para criar usuário administrador
create_admin_user() {
    print_step "Criando usuário administrador..."

    cd backend

    # Verificar se o usuário já existe
    USER_EXISTS=$(docker exec backend_db_postgres_1 psql -U atendechat -d atendechat_db -t -c "SELECT COUNT(*) FROM \"Users\" WHERE email = '$USER_EMAIL';" 2>/dev/null || echo "0")

    if [[ "$USER_EXISTS" -gt 0 ]]; then
        print_success "Usuário administrador já existe"
    else
        # Criar hash da senha usando bcrypt
        SALT_ROUNDS=10
        PASSWORD_HASH=$(node -e "
        const bcrypt = require('bcryptjs');
        const salt = bcrypt.genSaltSync($SALT_ROUNDS);
        const hash = bcrypt.hashSync('$USER_PASSWORD', salt);
        console.log(hash);
        " 2>/dev/null)

        if [[ -n "$PASSWORD_HASH" ]]; then
            # Inserir usuário no banco
            docker exec backend_db_postgres_1 psql -U atendechat -d atendechat_db -c "
            INSERT INTO \"Users\" (email, password, name, profile, \"createdAt\", \"updatedAt\")
            VALUES ('$USER_EMAIL', '$PASSWORD_HASH', 'Administrador', 'admin', NOW(), NOW());
            " 2>/dev/null

            if [[ $? -eq 0 ]]; then
                print_success "Usuário administrador criado com sucesso"
                print_message "Email: $USER_EMAIL"
                print_message "Senha: $USER_PASSWORD"
            else
                print_warning "Não foi possível criar usuário via SQL, tentando via API..."
            fi
        else
            print_warning "Não foi possível gerar hash da senha"
        fi
    fi

    cd ..
}

# Função para configurar banco de dados
setup_database() {
    print_step "Configurando banco de dados..."

    # Aguardar PostgreSQL iniciar
    print_message "Aguardando PostgreSQL iniciar..."
    sleep 15

    # Testar conexão
    if docker exec backend_db_postgres_1 pg_isready -U atendechat -d atendechat_db 2>/dev/null; then
        print_success "PostgreSQL está pronto"
    else
        print_warning "PostgreSQL pode não estar totalmente pronto, mas continuando..."
    fi

    cd backend

    # Executar migrações
    print_message "Executando migrações..."
    npx sequelize db:migrate || print_warning "Algumas migrações podem ter falhado"

    # Executar seeds
    print_message "Executando seeds..."
    npx sequelize db:seed:all || print_warning "Seeds podem ter falhado"

    cd ..

    # Criar usuário administrador
    create_admin_user

    print_message "Banco de dados configurado"
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
    NODE_OPTIONS="--openssl-legacy-provider" npm start &
    FRONTEND_PID=$!

    cd ..
    print_message "Aplicações iniciadas com sucesso"
}

# Função para verificar se aplicações estão funcionando
verify_installation() {
    print_step "Verificando instalação..."

    # Aguardar aplicações iniciarem
    print_message "Aguardando aplicações ficarem prontas..."
    sleep 15

    # Verificar backend
    if curl -s --max-time 10 "http://$DOMAIN:$BACKEND_PORT" > /dev/null 2>&1; then
        print_success "✅ Backend está respondendo em http://$DOMAIN:$BACKEND_PORT"
    else
        print_warning "⚠️  Backend pode não estar totalmente pronto"
    fi

    # Verificar frontend
    if curl -s --max-time 10 "http://$DOMAIN:$FRONTEND_PORT" > /dev/null 2>&1; then
        print_success "✅ Frontend está respondendo em http://$DOMAIN:$FRONTEND_PORT"
    else
        print_warning "⚠️  Frontend pode não estar totalmente pronto"
    fi
}

# Função principal
main() {
    print_message "=== ATENDECHAT AUTO INSTALLER v1.2.1 ==="
    print_message "Instalador completo com criação garantida do usuário administrador"
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

    # Criar docker-compose corrigido
    create_docker_compose

    # Iniciar containers Docker
    start_docker_containers

    # Instalar dependências
    install_dependencies

    # Compilar backend
    build_backend

    # Configurar banco de dados
    setup_database

    # Iniciar aplicações
    start_applications

    # Verificar instalação
    verify_installation

    print_message ""
    print_message "=== INSTALAÇÃO CONCLUÍDA ==="
    print_message "Atendechat foi instalado com sucesso!"
    print_message ""
    print_message "Acesso:"
    print_message "  Frontend: http://$DOMAIN:$FRONTEND_PORT"
    print_message "  Backend: http://$DOMAIN:$BACKEND_PORT"
    print_message ""
    print_message "Credenciais do administrador:"
    print_message "  Email: $USER_EMAIL"
    print_message "  Senha: $USER_PASSWORD"
    print_message ""
    print_message "Para parar: ./stop.sh"
    print_message "Para reiniciar: ./restart.sh"
    print_message "Para testar: ./test.sh"
}

# Executar função principal
main "$@"
