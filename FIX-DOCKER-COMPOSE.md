# Fix Docker Compose - Reverse Proxy Setup

El frontend debe estar en puerto 8080 (no 80) para que nginx pueda hacer de proxy.

## Ejecutar en la EC2

```bash
cd /opt/app

# Backup del compose actual
sudo cp docker-compose.yml docker-compose.yml.backup

# Crear el nuevo docker-compose.yml
sudo tee docker-compose.yml > /dev/null << 'EOF'
services:
  backend:
    image: ghcr.io/akaidmaru/muni-backend-deploy:latest
    container_name: app-backend
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      PORT: 3000
      NODE_TLS_REJECT_UNAUTHORIZED: 0
      DATABASE_URL: "${DATABASE_URL}"
      JWT_SECRET: "${JWT_SECRET}"
      REDIS_URL: "redis://redis:6379"
      REDIS_HOST: redis
      REDIS_PORT: 6379
      CORS_ORIGIN: "${CORS_ORIGIN}"
      VERIFICATION_CODE_TTL: "600"
      VERIFICATION_RATE_LIMIT_SECONDS: "60"
      GOOGLE_MAPS_API_KEY: "${GOOGLE_MAPS_API_KEY}"
      BREVO_API_KEY: "${BREVO_API_KEY}"
      BREVO_SENDER_EMAIL: "${BREVO_SENDER_EMAIL}"
      BREVO_SENDER_NAME: "${BREVO_SENDER_NAME}"
      AWS_REGION: us-east-1
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_S3_BUCKET: "${AWS_S3_BUCKET}"
      AWS_S3_SIGNED_URL_TTL: "3600"
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "node", "-e", "require('http').get('http://127.0.0.1:3000/api-docs',r=>process.exit(r.statusCode===200||r.statusCode===301||r.statusCode===302?0:1)).on('error',()=>process.exit(1))"]
      interval: 30s
      timeout: 5s
      start_period: 40s
      retries: 3

  frontend:
    image: ghcr.io/akaidmaru/muni-frontend-deploy:latest
    container_name: app-frontend
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://127.0.0.1:80/"]
      interval: 30s
      timeout: 5s
      start_period: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    container_name: app-redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    networks:
      - app-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      start_period: 5s
      retries: 5
    volumes:
      - redis-data:/data

networks:
  app-network:
    driver: bridge

volumes:
  redis-data:
    driver: local
EOF

# Validar sintaxis
docker compose config

# Si no hay errores, levantar
docker compose up -d

# Ver estado
docker ps
```

## Verificar que funciona

```bash
# Frontend debe responder en 8080
curl -I http://localhost:8080

# Backend debe responder en 3000
curl -I http://localhost:3000/api-docs

# Nginx debe enrutar correctamente
curl -H "Host: vectiaq.cl" http://localhost/
curl -H "Host: api.vectiaq.cl" http://localhost/api-docs
```

## Troubleshooting

Si `docker compose config` da error, verifica:
- Que el `.env` exista y tenga todas las variables
- Indentación correcta (usa espacios, no tabs)

Si nginx no funciona:
```bash
sudo nginx -t
sudo systemctl status nginx
sudo journalctl -u nginx -n 50
```
