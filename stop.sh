#!/bin/bash

# AtendeChat - Script de Parada com PM2
# Versão: 2.0.0
# Descrição: Para todo o sistema corretamente usando PM2

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

# Função para parar aplicações PM2
stop_pm2_apps() {
    print_step "Parando aplicações PM2..."

    # Verificar se existem processos PM2 rodando
    if pm2 list | grep -q "atendechat"; then
        # Parar aplicações
        pm2 stop ecosystem.config.js
        pm2 delete ecosystem.config.js

        print_success "Aplicações PM2 paradas"
    else
        print_message "Nenhuma aplicação PM2 rodando"
    fi
}

# Função para parar containers Docker
stop_containers() {
    print_step "Parando containers Docker..."

    cd atendechat/backend

    # Verificar se containers estão rodando
    if docker-compose -f docker-compose.databases.yml ps | grep -q "Up"; then
        docker-compose -f docker-compose.databases.yml down
        print_success "Containers Docker parados"
    else
        print_message "Containers Docker não estavam rodando"
    fi

    cd ../..
}

# Função para verificar se tudo foi parado
verify_stopped() {
    print_step "Verificando se tudo foi parado..."

    # Verificar processos PM2
    PM2_PROCESSES=$(pm2 list | grep -c "atendechat" || echo "0")
    if [[ $PM2_PROCESSES -eq 0 ]]; then
        print_success "✅ Todas as aplicações PM2 paradas"
    else
        print_warning "⚠️  Ainda há $PM2_PROCESSES aplicações PM2 rodando"
    fi

    # Verificar containers Docker
    RUNNING_CONTAINERS=$(docker ps | grep -c "backend_" || echo "0")
    if [[ $RUNNING_CONTAINERS -eq 0 ]]; then
        print_success "✅ Todos os containers Docker parados"
    else
        print_warning "⚠️  Ainda há $RUNNING_CONTAINERS containers rodando"
    fi
}

# Função para mostrar status final
show_final_status() {
    print_step "Status final do sistema:"

    echo "=== Aplicações PM2 ==="
    pm2 list --format "table {{.name}}\t{{.status}}\t{{.pid}}" | head -10

    echo ""
    echo "=== Containers Docker ==="
    docker ps --filter "name=atendechat" --filter "name=backend_" --format "table {{.Names}}\t{{.Status}}" || echo "Nenhum container rodando"
}

# Função principal
main() {
    print_message "=== ATENDECHAT - PARADA COM PM2 ==="
    print_message "Parando todo o sistema..."
    print_message ""

    # Parar aplicações PM2
    stop_pm2_apps

    # Parar containers Docker
    stop_containers

    # Verificar se tudo foi parado
    verify_stopped

    # Mostrar status final
    echo ""
    show_final_status

    print_message ""
    print_message "=== SISTEMA COMPLETAMENTE PARADO ==="
    print_message "AtendeChat foi parado com sucesso!"
    print_message ""
    print_message "Para iniciar novamente: ./start.sh"
    print_message "Para verificar status: ./status.sh"
    print_message ""
    print_message "Comandos PM2 úteis:"
    print_message "  Ver logs: pm2 logs"
    print_message "  Ver status: pm2 status"
    print_message "  Limpar logs: pm2 flush"
}

# Executar função principal
main "$@"
