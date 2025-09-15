#!/bin/bash

# AtendeChat - Script de Inicialização Simples
# Versão: 1.0.0
# Descrição: Inicia todo o sistema sem PM2 (processos em background)

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

    cd atendechat/backend

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

    cd ..
}

# Função para configurar banco de dados
setup_database() {
    print_step "Configurando banco de dados..."

    cd atendechat/backend

    # Executar migrations
    print_message "Executando migrations..."
    npm run db:migrate || print_warning "Algumas migrations podem já ter sido executadas"

    # Executar seeds
    print_message "Executando seeds..."
    npm run db:seed || print_warning "Seeds podem já ter sido executados"

    cd ..

    print_success "Banco de dados configurado"
}

# Função para iniciar aplicações em background
start_applications() {
    print_step "Iniciando aplicações em background..."

    # Iniciar backend
    print_message "Iniciando backend..."
    cd atendechat/backend
    nohup npm run dev:server > ../logs/backend.log 2>&1 &
    BACKEND_PID=$!
    print_success "Backend iniciado (PID: $BACKEND_PID)"
    cd ../..

    # Aguardar backend iniciar
    sleep 5

    # Iniciar frontend
    print_message "Iniciando frontend..."
    cd atendechat/frontend
    nohup NODE_OPTIONS="--openssl-legacy-provider" npm start > ../logs/frontend.log 2>&1 &
    FRONTEND_PID=$!
    print_success "Frontend iniciado (PID: $FRONTEND_PID)"
    cd ../..

    print_message ""
    print_warning "⚠️  IMPORTANTE: Os processos estão rodando em background"
    print_warning "⚠️  Eles PARARÃO quando você fechar o terminal"
    print_warning "⚠️  Para manter rodando, use screen/tmux ou PM2"
    print_message ""
    print_message "Para ver logs:"
    print_message "  Backend: tail -f logs/backend.log"
    print_message "  Frontend: tail -f logs/frontend.log"
    print_message ""
    print_message "Para parar: ./stop.sh"
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
    print_message "=== ATENDECHAT - INICIALIZAÇÃO SIMPLES ==="
    print_message "Iniciando todo o sistema (processos em background)..."
    print_message ""

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

    # Iniciar aplicações
    start_applications

    # Verificar sistema
    verify_system

    print_message ""
    print_message "=== SISTEMA INICIADO ==="
    print_message "AtendeChat está rodando!"
    print_message ""
    print_message "⚠️  AVISO: Processos param ao fechar terminal"
    print_message "💡 Para manter rodando: use screen/tmux ou PM2"
    print_message ""
    print_message "Acesso:"
    print_message "  Frontend: http://localhost:3000"
    print_message "  Backend:  http://localhost:8080"
    print_message ""
    print_message "Para parar: ./stop.sh"
    print_message "Para verificar: ./status.sh"
}

# Executar função principal
main "$@"
