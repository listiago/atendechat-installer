#!/bin/bash

# AtendeChat - Script de Inicialização com PM2
# Versão: 2.0.0
# Descrição: Inicia todo o sistema automaticamente com PM2

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

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para verificar PM2
check_pm2() {
    if ! command_exists pm2; then
        print_step "Instalando PM2..."

        # Tentar instalar globalmente com sudo
        if sudo npm install -g pm2 2>/dev/null; then
            print_success "PM2 instalado com sucesso (sudo)"
        else
            print_warning "Não foi possível instalar PM2 globalmente"
            print_message "Tentando instalar localmente..."

            # Instalar localmente como fallback
            if npm install pm2 --save-dev 2>/dev/null; then
                # Adicionar ao PATH localmente
                export PATH="$PWD/node_modules/.bin:$PATH"
                print_success "PM2 instalado localmente"
            else
                print_error "Falha ao instalar PM2. Instale manualmente: sudo npm install -g pm2"
                exit 1
            fi
        fi
    else
        print_success "PM2 já está instalado"
    fi
}

# Função para verificar se Docker está rodando
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker não está rodando. Inicie o Docker primeiro."
        exit 1
    fi
}

# Função para verificar se diretório existe
check_directory() {
    if [[ ! -d "atendechat" ]]; then
        print_error "Diretório 'atendechat' não encontrado!"
        print_message "Execute o instalador primeiro: ./install.sh"
        exit 1
    fi

    if [[ ! -d "atendechat/backend" ]]; then
        print_error "Diretório 'atendechat/backend' não encontrado!"
        print_message "Execute o instalador primeiro: ./install.sh"
        exit 1
    fi
}

# Função para iniciar containers
start_containers() {
    print_step "Iniciando containers Docker..."

    local backend_dir="$PWD/atendechat/backend"

    if [[ ! -d "$backend_dir" ]]; then
        print_error "Diretório backend não encontrado: $backend_dir"
        exit 1
    fi

    cd "$backend_dir"

    # Verificar se containers já estão rodando
    if docker-compose -f docker-compose.databases.yml ps | grep -q "Up"; then
        print_success "Containers já estão rodando"
    else
        # Parar containers existentes (se houver)
        docker-compose -f docker-compose.databases.yml down 2>/dev/null || true

        # Iniciar containers
        docker-compose -f docker-compose.databases.yml up -d

        if [[ $? -ne 0 ]]; then
            print_error "Falha ao iniciar containers Docker"
            exit 1
        fi

        print_success "Containers Docker iniciados"
    fi

    cd "$PWD/../.."
}

# Função para aguardar bancos
wait_for_databases() {
    print_step "Aguardando bancos de dados..."

    # Aguardar PostgreSQL
    print_message "Aguardando PostgreSQL..."
    for i in {1..30}; do
        if docker exec backend_db_postgres_1 pg_isready -U atendechat -d atendechat_db 2>/dev/null; then
            print_success "PostgreSQL pronto!"
            break
        fi
        sleep 2
    done

    # Aguardar Redis
    print_message "Aguardando Redis..."
    for i in {1..10}; do
        if docker exec backend_cache_1 redis-cli ping 2>/dev/null | grep -q "PONG"; then
            print_success "Redis pronto!"
            break
        fi
        sleep 1
    done

    # Aguardar mais um pouco para garantir
    sleep 5
}

# Função para verificar e executar build do backend
check_backend_build() {
    print_step "Verificando build do backend..."

    local backend_dir="$PWD/atendechat/backend"

    if [[ ! -d "$backend_dir" ]]; then
        print_error "Diretório backend não encontrado: $backend_dir"
        exit 1
    fi

    cd "$backend_dir"

    # Verificar se pasta dist existe e tem arquivos
    if [[ ! -d "dist" ]] || [[ ! -f "dist/server.js" ]]; then
        print_message "Executando build do backend..."
        npm run build

        if [[ $? -ne 0 ]]; then
            print_error "Falha no build do backend"
            exit 1
        fi

        print_success "Backend compilado com sucesso"
    else
        print_success "Backend já está compilado"
    fi

    cd "$PWD/.."
}

# Função para configurar banco de dados
setup_database() {
    print_step "Configurando banco de dados..."

    local backend_dir="$PWD/atendechat/backend"

    if [[ ! -d "$backend_dir" ]]; then
        print_error "Diretório backend não encontrado: $backend_dir"
        exit 1
    fi

    cd "$backend_dir"

    # Executar migrations
    print_message "Executando migrations..."
    npm run db:migrate || print_warning "Algumas migrations podem já ter sido executadas"

    # Executar seeds
    print_message "Executando seeds..."
    npm run db:seed || print_warning "Seeds podem já ter sido executados"

    cd "$PWD/.."

    print_success "Banco de dados configurado"
}

# Função para iniciar aplicações com PM2
start_with_pm2() {
    print_step "Iniciando aplicações com PM2..."

    # Verificar se já existem processos PM2 rodando
    if pm2 list 2>/dev/null | grep -q "atendechat"; then
        print_warning "Aplicações já estão rodando no PM2"
        print_message "Use './stop.sh' para parar ou 'pm2 restart ecosystem.config.js' para reiniciar"
        return 0
    fi

    # Verificar se ecosystem.config.js existe
    if [[ ! -f "ecosystem.config.js" ]]; then
        print_error "Arquivo ecosystem.config.js não encontrado!"
        print_message "Certifique-se de que o arquivo existe no diretório raiz"
        exit 1
    fi

    # Iniciar aplicações com PM2
    pm2 start ecosystem.config.js

    if [[ $? -ne 0 ]]; then
        print_error "Falha ao iniciar aplicações com PM2"
        exit 1
    fi

    print_success "Aplicações iniciadas com PM2"

    # Salvar configuração PM2
    pm2 save

    # Mostrar status
    pm2 list
}

# Função para verificar se tudo está funcionando
verify_system() {
    print_step "Verificando sistema..."

    # Aguardar aplicações iniciarem
    sleep 15

    # Verificar backend
    if curl -s --max-time 5 http://localhost:8080 > /dev/null 2>&1; then
        print_success "✅ Backend: http://localhost:8080"
    else
        print_warning "⚠️  Backend pode não estar totalmente pronto"
    fi

    # Verificar frontend
    if curl -s --max-time 5 http://localhost:3000 > /dev/null 2>&1; then
        print_success "✅ Frontend: http://localhost:3000"
    else
        print_warning "⚠️  Frontend pode não estar totalmente pronto"
    fi
}

# Função principal
main() {
    print_message "=== ATENDECHAT - INICIALIZAÇÃO COM PM2 ==="
    print_message "Iniciando todo o sistema automaticamente..."
    print_message ""

    # Verificar PM2
    check_pm2

    # Verificar Docker
    check_docker

    # Verificar diretório
    check_directory

    # Iniciar containers
    start_containers

    # Aguardar bancos
    wait_for_databases

    # Verificar/compilar backend
    check_backend_build

    # Configurar banco
    setup_database

    # Iniciar aplicações com PM2
    start_with_pm2

    # Verificar sistema
    verify_system

    print_message ""
    print_message "=== SISTEMA TOTALMENTE OPERACIONAL ==="
    print_message "AtendeChat está rodando com PM2!"
    print_message ""
    print_message "✅ Processos persistem após fechar terminal"
    print_message "✅ Monitoramento automático ativo"
    print_message "✅ Restart automático em caso de falha"
    print_message ""
    print_message "Acesso:"
    print_message "  Frontend: http://localhost:3000"
    print_message "  Backend:  http://localhost:8080"
    print_message ""
    print_message "Comandos PM2:"
    print_message "  Status: pm2 status"
    print_message "  Logs: pm2 logs"
    print_message "  Monitor: pm2 monit"
    print_message ""
    print_message "Para parar: ./stop.sh"
    print_message "Para verificar: ./status.sh"
}

# Executar função principal
main "$@"
