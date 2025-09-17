#!/bin/bash

# AtendeChat - Configuração PM2 Startup
# Versão: 1.0.0
# Descrição: Configura PM2 para iniciar automaticamente no boot

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

# Função principal
main() {
    print_message "=== ATENDECHAT - CONFIGURAÇÃO PM2 STARTUP ==="
    print_message "Configurando inicialização automática no boot..."
    print_message ""

    # Verificar se PM2 está instalado
    if ! command_exists pm2; then
        print_error "❌ PM2 não está instalado!"
        print_message "Instale primeiro: sudo npm install -g pm2"
        exit 1
    fi
    print_success "✅ PM2 encontrado"

    # Verificar se estamos no diretório correto
    if [[ ! -f "ecosystem.config.js" ]]; then
        print_error "❌ Arquivo ecosystem.config.js não encontrado!"
        print_message "Execute este script do diretório atendechat-installer"
        exit 1
    fi
    print_success "✅ Arquivo de configuração encontrado"

    # Verificar se aplicações estão rodando
    if ! pm2 list 2>/dev/null | grep -q "atendechat"; then
        print_warning "⚠️  Aplicações não estão rodando no PM2"
        print_message "Inicie primeiro: ./start.sh"
        exit 1
    fi
    print_success "✅ Aplicações rodando no PM2"

    # Salvar configuração atual
    print_step "Salvando configuração PM2..."
    pm2 save

    if [[ $? -eq 0 ]]; then
        print_success "✅ Configuração salva com sucesso"
    else
        print_error "❌ Falha ao salvar configuração"
        exit 1
    fi

    # Configurar startup
    print_step "Configurando inicialização automática..."
    print_message "Execute o comando que aparecerá abaixo:"
    echo ""

    pm2 startup

    echo ""
    print_message "📋 APÓS EXECUTAR O COMANDO ACIMA:"
    print_message ""
    print_message "1️⃣  Execute: pm2 save"
    print_message "2️⃣  Teste: sudo reboot"
    print_message "3️⃣  Verifique: pm2 status"
    print_message ""

    print_success "🎉 CONFIGURAÇÃO PM2 STARTUP PRONTA!"
    print_message ""
    print_message "💡 Agora suas aplicações iniciarão automaticamente:"
    print_message "   ✅ Após reinicialização do servidor"
    print_message "   ✅ Após logout do usuário"
    print_message "   ✅ Após fechamento do terminal"
    print_message ""
    print_message "🔧 Comandos úteis:"
    print_message "   pm2 status    - Ver status das aplicações"
    print_message "   pm2 logs      - Ver logs em tempo real"
    print_message "   pm2 monit     - Monitor interativo"
    print_message "   pm2 stop all  - Parar todas as aplicações"
}

# Executar função principal
main "$@"
