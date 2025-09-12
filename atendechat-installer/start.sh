#!/bin/bash

# Atendechat Start Script
# Versão: 1.0.0
# Descrição: Script para iniciar automaticamente o Atendechat

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

# Função para verificar se diretório existe
check_directory() {
    if [[ ! -d "atendechat" ]]; then
        print_error "Diretório 'atendechat' não encontrado!"
        print_message "Execute o instalador primeiro: ./install.sh"
        exit 1
    fi
}

# Função para iniciar containers
start_containers() {
    print_step "Iniciando containers Docker..."

    cd atendechat/backend

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

    cd ../..
}

# Função para aguardar bancos
wait_for_databases() {
    print_step "Aguardando bancos de dados..."

    # Aguardar PostgreSQL
    print_message "Aguardando PostgreSQL..."
    for i in {1..30}; do
        if docker exec atendechat_db_postgres_1 pg_isready -U atendechat -d atendechat_db 2>/dev/null; then
            print_success "PostgreSQL pronto!"
            break
        fi
        sleep 2
    done

    # Aguardar Redis
    print_message "Aguardando Redis..."
    for i in {1..10}; do
        if docker exec atendechat_cache_1 redis-cli ping 2>/dev/null | grep -q "PONG"; then
            print_success "Redis pronto!"
            break
        fi
        sleep 1
    done

    # Aguardar mais um pouco para garantir
    sleep 5
}

# Função para iniciar backend
start_backend() {
    print_step "Iniciando backend..."

    cd atendechat/backend

    # Verificar se já está rodando
    if ps aux | grep -v grep | grep -q "ts-node-dev"; then
        print_success "Backend já está rodando"
    else
        # Iniciar backend
        npm run dev:server &
        BACKEND_PID=$!

        print_success "Backend iniciado (PID: $BACKEND_PID)"
    fi

    cd ../..
}

# Função para iniciar frontend
start_frontend() {
    print_step "Iniciando frontend..."

    cd atendechat/frontend

    # Verificar se já está rodando
    if ps aux | grep -v grep | grep -q "react-scripts"; then
        print_success "Frontend já está rodando"
    else
        # Iniciar frontend
        npm start &
        FRONTEND_PID=$!

        print_success "Frontend iniciado (PID: $FRONTEND_PID)"
    fi

    cd ../..
}

# Função para verificar se tudo está funcionando
verify_system() {
    print_step "Verificando sistema..."

    # Aguardar aplicações iniciarem
    sleep 10

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
    print_message "=== ATENDECHAT START SCRIPT ==="
    print_message "Iniciando sistema automaticamente..."
    print_message ""

    # Verificar diretório
    check_directory

    # Iniciar containers
    start_containers

    # Aguardar bancos
    wait_for_databases

    # Iniciar backend
    start_backend

    # Iniciar frontend
    start_frontend

    # Verificar sistema
    verify_system

    print_message ""
    print_message "=== SISTEMA INICIADO ==="
    print_message "Atendechat está rodando!"
    print_message ""
    print_message "Acesso:"
    print_message "  Frontend: http://localhost:3000"
    print_message "  Backend: http://localhost:8080"
    print_message ""
    print_message "Para parar: ./stop.sh"
    print_message "Para verificar: ./test.sh"
}

# Executar função principal
main "$@"
