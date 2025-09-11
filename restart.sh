#!/bin/bash

# Atendechat Restart Script
# Versão: 1.1.0
# Descrição: Script para reiniciar aplicações do Atendechat

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

# Função para parar aplicações
stop_applications() {
    print_step "Parando aplicações existentes..."

    # Parar processos Node.js
    pkill -f 'node.*server.ts' 2>/dev/null || print_warning "Nenhum processo de backend encontrado"
    pkill -f 'react-scripts start' 2>/dev/null || print_warning "Nenhum processo de frontend encontrado"

    # Aguardar processos terminarem
    sleep 3

    print_message "Aplicações paradas"
}

# Função para verificar containers Docker
check_docker_containers() {
    print_step "Verificando containers Docker..."

    if ! docker ps | grep -q "db_postgres\|cache"; then
        print_warning "Containers Docker não estão rodando"
        print_message "Iniciando containers..."

        cd backend
        docker-compose -f docker-compose.databases.yml up -d

        if [[ $? -ne 0 ]]; then
            print_error "Falha ao iniciar containers Docker"
            exit 1
        fi

        print_message "Containers Docker iniciados"
        cd ..
    else
        print_message "Containers Docker estão rodando"
    fi
}

# Função para iniciar backend
start_backend() {
    print_step "Iniciando backend..."

    cd backend

    # Verificar se .env existe
    if [[ ! -f .env ]]; then
        print_error "Arquivo .env não encontrado no backend"
        print_message "Execute o instalador primeiro: ./install.sh"
        exit 1
    fi

    # Iniciar backend
    npm run dev:server &
    BACKEND_PID=$!

    print_message "Backend iniciado (PID: $BACKEND_PID)"
    cd ..
}

# Função para iniciar frontend
start_frontend() {
    print_step "Iniciando frontend..."

    cd frontend

    # Verificar se .env existe
    if [[ ! -f .env ]]; then
        print_error "Arquivo .env não encontrado no frontend"
        print_message "Execute o instalador primeiro: ./install.sh"
        exit 1
    fi

    # Iniciar frontend
    npm start &
    FRONTEND_PID=$!

    print_message "Frontend iniciado (PID: $FRONTEND_PID)"
    cd ..
}

# Função para verificar se aplicações estão respondendo
check_applications() {
    print_step "Verificando aplicações..."

    # Ler configurações do .env
    if [[ -f backend/.env ]]; then
        source backend/.env
        BACKEND_URL="${BACKEND_URL:-http://localhost}"
        PORT="${PORT:-8080}"
    else
        BACKEND_URL="http://localhost"
        PORT="8080"
    fi

    if [[ -f frontend/.env ]]; then
        source frontend/.env
        FRONTEND_PORT=$(echo $REACT_APP_BACKEND_URL | grep -oP '(?<=:)(\d+)')
        if [[ -z "$FRONTEND_PORT" ]]; then
            FRONTEND_PORT="3000"
        fi
    else
        FRONTEND_PORT="3000"
    fi

    # Aguardar aplicações iniciarem
    print_message "Aguardando aplicações ficarem prontas..."
    sleep 10

    # Verificar backend
    if curl -s --max-time 5 "${BACKEND_URL}:${PORT}/health" > /dev/null 2>&1; then
        print_message "✅ Backend está respondendo em ${BACKEND_URL}:${PORT}"
    else
        print_warning "⚠️  Backend pode não estar totalmente pronto"
    fi

    # Verificar frontend (porta padrão do React)
    if curl -s --max-time 5 "http://localhost:${FRONTEND_PORT}" > /dev/null 2>&1; then
        print_message "✅ Frontend está respondendo em http://localhost:${FRONTEND_PORT}"
    else
        print_warning "⚠️  Frontend pode não estar totalmente pronto"
    fi
}

# Função para mostrar status
show_status() {
    print_message ""
    print_message "=== STATUS DAS APLICAÇÕES ==="

    # Mostrar processos
    print_message "Processos Node.js:"
    ps aux | grep -E '(node|npm)' | grep -v grep || print_message "Nenhum processo encontrado"

    print_message ""
    print_message "Containers Docker:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E '(db_postgres|cache)' || print_message "Nenhum container encontrado"

    print_message ""
    print_message "Para ver logs em tempo real:"
    print_message "  Backend: tail -f /dev/null & npm run dev:server (em outro terminal)"
    print_message "  Frontend: tail -f /dev/null & npm start (em outro terminal)"
    print_message "  Docker: docker-compose -f backend/docker-compose.databases.yml logs -f"
}

# Função principal
main() {
    print_message "=== ATENDECHAT RESTART SCRIPT ==="
    print_message "Reiniciando aplicações..."
    print_message ""

    # Verificar se estamos no diretório correto
    if [[ ! -d "backend" || ! -d "frontend" ]]; then
        print_error "Diretórios backend/ e frontend/ não encontrados"
        print_message "Execute este script dentro do diretório atendechat/"
        print_message "Ou execute o instalador primeiro: ./install.sh"
        exit 1
    fi

    # Parar aplicações existentes
    stop_applications

    # Verificar containers Docker
    check_docker_containers

    # Iniciar backend
    start_backend

    # Aguardar backend iniciar
    sleep 5

    # Iniciar frontend
    start_frontend

    # Verificar aplicações
    check_applications

    # Mostrar status
    show_status

    print_message ""
    print_message "=== RESTART CONCLUÍDO ==="
    print_message "Atendechat foi reiniciado com sucesso!"
    print_message ""
    print_message "Para parar: ./stop.sh ou pkill -f 'node\|npm'"
}

# Executar função principal
main "$@"
