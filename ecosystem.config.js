module.exports = {
  apps: [
    {
      name: 'atendechat-backend',
      script: 'backend/dist/server.js',
      cwd: './atendechat',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'development',
        PORT: 8080
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 8080
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend.log',
      time: true,
      watch: false,
      max_memory_restart: '1G',
      restart_delay: 4000,
      autorestart: true,
      min_uptime: '10s'
    },
    {
      name: 'atendechat-frontend',
      script: 'npm',
      args: 'start',
      cwd: './atendechat/frontend',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'development',
        PORT: 3000,
        BROWSER: 'none'
      },
      env_production: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: './logs/frontend-error.log',
      out_file: './logs/frontend-out.log',
      log_file: './logs/frontend.log',
      time: true,
      watch: false,
      max_memory_restart: '500M',
      restart_delay: 4000,
      autorestart: true,
      min_uptime: '10s'
    }
  ],

  deploy: {
    production: {
      user: 'node',
      host: 'your-server.com',
      ref: 'origin/main',
      repo: 'git@github.com:listiago/atendechat.git',
      path: '/var/www/atendechat',
      'pre-deploy-local': '',
      'post-deploy': 'npm install && pm2 reload ecosystem.config.js --env production',
      'pre-setup': ''
    }
  }
};
