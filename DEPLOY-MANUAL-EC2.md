# Deploy Manual en EC2 (Sin GitHub Actions)

Este manual describe cómo desplegar la aplicación **Transportes Flores Vargas** compilando las imágenes Docker directamente en la instancia EC2, sin usar GitHub Actions ni GitHub Container Registry (GHCR).

---

## Prerrequisitos

Antes de comenzar, asegúrate de tener:

- ✅ Infraestructura AWS desplegada con Terraform (`terraform apply` ejecutado)
- ✅ Instancia EC2 con Docker y Docker Compose instalados (Ansible role `docker`)
- ✅ Archivo `/opt/app/.env` generado por Ansible con credenciales correctas
- ✅ Acceso SSH a la instancia EC2
- ✅ Repositorios Git accesibles (públicos o con credenciales configuradas)

**IP de la EC2 en este ejemplo:** `44.204.104.240`

---

## 1. Conectarse a la EC2

```bash
# Desde tu máquina local (directorio infra-transportes-flores)
ssh -i keypairs/transportes_floresV.pem ubuntu@44.204.104.240
```

---

## 2. Preparar Directorio de Aplicaciones

```bash
# Crear estructura de directorios
mkdir -p /home/ubuntu/apps
cd /home/ubuntu/apps

# Verificar que tenemos git instalado
git --version
```

Si `git` no está instalado:
```bash
sudo apt update
sudo apt install -y git
```

---

## 3. Clonar los Repositorios

```bash
cd /home/ubuntu/apps

# Clonar backend
git clone https://github.com/TU-ORG/Muni-backend.git
# O si es privado:
# git clone https://github.com/TU-ORG/Muni-backend.git
# (te pedirá credenciales o usa SSH key)

# Clonar frontend
git clone https://github.com/TU-ORG/Muni-front.git

# Verificar que se clonaron correctamente
ls -la
# Deberías ver: Muni-backend/ y Muni-front/
```

**Nota sobre repositorios privados:**
Si los repos son privados, configura credenciales:
```bash
# Opción 1: HTTPS con Personal Access Token
git config --global credential.helper store
git clone https://TU-USERNAME:TU-TOKEN@github.com/TU-ORG/Muni-backend.git

# Opción 2: SSH key (recomendado)
# Genera una key en la EC2 y agrégala a GitHub
ssh-keygen -t ed25519 -C "ubuntu@ec2"
cat ~/.ssh/id_ed25519.pub  # Agrega esta key a GitHub Settings → SSH keys
```

---

## 4. Modificar `docker-compose.yml`

### Opción A: Build directo en compose (recomendado para desarrollo)

Edita `/opt/app/docker-compose.yml`:

```bash
sudo nano /opt/app/docker-compose.yml
```

Reemplaza el contenido con:

```yaml
# Deploy manual: build desde código fuente en EC2
services:
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - tfv-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3

  backend:
    build:
      context: /home/ubuntu/apps/Muni-backend
      dockerfile: Dockerfile
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "3000:3000"
    depends_on:
      redis:
        condition: service_healthy
    networks:
      - tfv-network

  frontend:
    build:
      context: /home/ubuntu/apps/Muni-front
      dockerfile: Dockerfile
      args:
        # IMPORTANTE: debe coincidir con tfv_public_api_url
        VITE_API_BASE_URL: http://44.204.104.240:3000
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - tfv-network

networks:
  tfv-network:
    driver: bridge
```

**Importante:** Cambia `44.204.104.240` por la IP real de tu EC2 (output `ec2_public_ip` de Terraform).

### Opción B: Build previo + tags locales

Si prefieres compilar las imágenes antes y luego referenciarlas:

```yaml
services:
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - tfv-network

  backend:
    image: muni-backend:local  # Tag local
    restart: unless-stopped
    env_file:
      - .env
    ports:
      - "3000:3000"
    depends_on:
      - redis
    networks:
      - tfv-network

  frontend:
    image: muni-frontend:local  # Tag local
    restart: unless-stopped
    ports:
      - "8080:80"
    depends_on:
      - backend
    networks:
      - tfv-network

networks:
  tfv-network:
    driver: bridge
```

---

## 5. Compilar las Imágenes Docker

### Si usas Opción A (build en compose):

```bash
cd /opt/app
sudo docker compose build --no-cache
```

Esto puede tardar varios minutos la primera vez (descarga dependencias npm, etc.).

**Salida esperada:**
```
[+] Building 250.3s (24/24) FINISHED
 => [backend] ...
 => [frontend] ...
```

### Si usas Opción B (build previo):

```bash
# Compilar backend
cd /home/ubuntu/apps/Muni-backend
sudo docker build -t muni-backend:local .

# Compilar frontend (CON el build-arg)
cd /home/ubuntu/apps/Muni-front
sudo docker build \
  --build-arg VITE_API_BASE_URL=http://44.204.104.240:3000 \
  -t muni-frontend:local .
```

**⚠️ Crítico para el frontend:** El `--build-arg VITE_API_BASE_URL` debe coincidir con la URL pública del API. Si la IP cambia después de un `terraform destroy/apply`, debes **rebuill** el frontend.

---

## 6. Verificar Variables de Entorno

Antes de levantar el stack, verifica que el `.env` tenga las variables correctas:

```bash
sudo cat /opt/app/.env
```

**Debes ver:**
```
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://tfvadmin:PASSWORD@tfv-produccion.c6zwy2260qhw....rds.amazonaws.com:5432/tfvapp
JWT_SECRET=tu_secreto_jwt
AWS_REGION=us-east-1
S3_BUCKET=transportes-flores-vargas-...-app
CORS_ORIGIN=http://44.204.104.240:8080
REDIS_URL=redis://redis:6379
PUBLIC_API_URL=http://44.204.104.240:3000
VERIFICATION_CODE_TTL=600
TFV_BACKEND_IMAGE=muni-backend:local
TFV_FRONTEND_IMAGE=muni-frontend:local
```

Si falta algo o los valores están incorrectos, **vuelve a ejecutar Ansible**:
```bash
# Desde tu máquina local (directorio ansible/)
ansible-playbook -i ansible_inventory ec2provisioning.yml --ask-vault-pass
```

---

## 7. Levantar el Stack

```bash
cd /opt/app
sudo docker compose up -d
```

**Salida esperada:**
```
[+] Running 4/4
 ✔ Network tfv-network    Created
 ✔ Container app-redis-1     Started
 ✔ Container app-backend-1   Started
 ✔ Container app-frontend-1  Started
```

---

## 8. Verificar el Despliegue

### 8.1. Estado de los contenedores

```bash
sudo docker ps
```

**Salida esperada:**
```
CONTAINER ID   IMAGE                  STATUS                    PORTS
abc123         muni-backend:local     Up 2 minutes (healthy)    0.0.0.0:3000->3000/tcp
def456         muni-frontend:local    Up 2 minutes (healthy)    0.0.0.0:8080->80/tcp
ghi789         redis:7-alpine         Up 2 minutes              6379/tcp
```

**✅ IMPORTANTE:** La columna `STATUS` debe mostrar `(healthy)` después de ~40 segundos.

Si ves `(unhealthy)` o `(health: starting)` por mucho tiempo, revisa los logs.

### 8.2. Logs del backend

```bash
sudo docker logs app-backend-1 -f
```

**Busca:**
```
Prisma schema loaded from prisma/schema.prisma
Datasource "db": PostgreSQL database "tfvapp"

Running migration: 20260202001639_init_models
...
Database migrations have been applied successfully.

[Nest] 1  - 03/28/2026, 10:15:30 PM     LOG [NestApplication] Nest application successfully started
[Nest] 1  - 03/28/2026, 10:15:30 PM     LOG Application is running on: http://0.0.0.0:3000
```

**⚠️ Si ves errores:**
- `ECONNREFUSED` → RDS no accesible (verifica Security Group)
- `password authentication failed` → Password incorrecto en `.env` (debe coincidir con Terraform)
- `connect ECONNREFUSED redis:6379` → Redis no arrancó (verifica `docker ps`)

### 8.3. Logs del frontend

```bash
sudo docker logs app-frontend-1
```

**Salida esperada (nginx):**
```
/docker-entrypoint.sh: ...
2026/03/28 22:15:30 [notice] 1#1: start worker processes
```

### 8.4. Probar endpoints

**Desde la EC2:**
```bash
# API (Swagger)
curl http://localhost:3000/api-docs

# Frontend
curl http://localhost:8080
```

**Desde tu navegador:**
- Frontend: `http://44.204.104.240:8080`
- API: `http://44.204.104.240:3000/api-docs`

**✅ Si funciona:**
- Frontend carga la aplicación Vue
- Swagger muestra la documentación del API
- Consola del navegador **no** tiene errores CORS

---

## 9. Script de Deploy Automatizado

Crea un script para automatizar futuros deploys:

```bash
sudo nano /opt/app/deploy.sh
```

Contenido:

```bash
#!/bin/bash
set -euo pipefail

echo "======================================"
echo "  Deploy Transportes Flores Vargas"
echo "======================================"
echo ""

# Variables
BACKEND_DIR="/home/ubuntu/apps/Muni-backend"
FRONTEND_DIR="/home/ubuntu/apps/Muni-front"
APP_DIR="/opt/app"
API_URL="http://44.204.104.240:3000"  # Cambia por tu IP

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}[1/7]${NC} Actualizando código fuente..."
cd "$BACKEND_DIR" && git pull origin main
cd "$FRONTEND_DIR" && git pull origin main
echo -e "${GREEN}✓ Código actualizado${NC}"
echo ""

echo -e "${YELLOW}[2/7]${NC} Deteniendo contenedores..."
cd "$APP_DIR"
docker compose down
echo -e "${GREEN}✓ Contenedores detenidos${NC}"
echo ""

echo -e "${YELLOW}[3/7]${NC} Compilando imagen backend..."
cd "$BACKEND_DIR"
docker build -t muni-backend:local . || {
  echo -e "${RED}✗ Error compilando backend${NC}"
  exit 1
}
echo -e "${GREEN}✓ Backend compilado${NC}"
echo ""

echo -e "${YELLOW}[4/7]${NC} Compilando imagen frontend..."
cd "$FRONTEND_DIR"
docker build \
  --build-arg "VITE_API_BASE_URL=${API_URL}" \
  -t muni-frontend:local . || {
  echo -e "${RED}✗ Error compilando frontend${NC}"
  exit 1
}
echo -e "${GREEN}✓ Frontend compilado${NC}"
echo ""

echo -e "${YELLOW}[5/7]${NC} Levantando stack..."
cd "$APP_DIR"
docker compose up -d
echo -e "${GREEN}✓ Stack levantado${NC}"
echo ""

echo -e "${YELLOW}[6/7]${NC} Esperando que los servicios estén listos..."
sleep 15
echo ""

echo -e "${YELLOW}[7/7]${NC} Verificando salud de los contenedores..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo -e "${GREEN}======================================"
echo "  Deploy completado exitosamente"
echo "======================================${NC}"
echo ""
echo "URLs:"
echo "  Frontend: http://44.204.104.240:8080"
echo "  API:      http://44.204.104.240:3000"
echo "  Swagger:  http://44.204.104.240:3000/api-docs"
echo ""
echo "Para ver logs:"
echo "  Backend:  docker logs app-backend-1 -f"
echo "  Frontend: docker logs app-frontend-1 -f"
```

Dar permisos de ejecución:

```bash
sudo chmod +x /opt/app/deploy.sh
```

**Uso:**
```bash
sudo /opt/app/deploy.sh
```

---

## 10. Actualizar la Aplicación

Cuando quieras desplegar una nueva versión:

```bash
# Opción 1: Usar el script
sudo /opt/app/deploy.sh

# Opción 2: Manual
cd /home/ubuntu/apps/Muni-backend && git pull
cd /home/ubuntu/apps/Muni-front && git pull
cd /opt/app
sudo docker compose down
sudo docker compose build --no-cache
sudo docker compose up -d
```

**⚠️ Importante:** Si cambió la IP de la EC2 (después de `terraform destroy/apply`):
1. Actualiza `VITE_API_BASE_URL` en `docker-compose.yml` o en el script
2. Actualiza `/opt/app/.env` (o vuelve a ejecutar Ansible)
3. Rebuild las imágenes

---

## 11. Troubleshooting

### Problema: Backend no arranca

**Síntoma:**
```bash
$ docker logs app-backend-1
Error: P1001: Can't reach database server at `tfv-produccion...`
```

**Solución:**
1. Verificar Security Group de RDS permite conexiones desde EC2:
   ```bash
   # Desde la EC2, probar conexión
   telnet tfv-produccion.c6zwy2260qhw.us-east-1.rds.amazonaws.com 5432
   ```
   
2. Verificar credenciales en `/opt/app/.env`:
   ```bash
   sudo cat /opt/app/.env | grep DATABASE_URL
   ```
   Debe coincidir con el password de RDS en Terraform.

### Problema: Frontend carga pero no llama al API

**Síntoma:** Consola del navegador muestra errores de red o CORS.

**Solución:**
1. Verificar que la URL embebida en el frontend es correcta:
   ```bash
   # Desde la EC2
   sudo docker exec app-frontend-1 cat /usr/share/nginx/html/assets/*.js | grep -o 'http://[^"]*:3000' | head -1
   ```
   
2. Si la URL está mal, rebuild del frontend con el `--build-arg` correcto.

3. Verificar CORS en backend:
   ```bash
   sudo cat /opt/app/.env | grep CORS_ORIGIN
   # Debe ser: http://44.204.104.240:8080
   ```

### Problema: "Out of memory" durante build

**Síntoma:** Build falla con `Killed` o el sistema se congela.

**Solución:**
1. La instancia `t3.micro` tiene solo 1 GB RAM. Durante el build de frontend (Vite), puede quedarse corta.

2. **Temporal:** Escala la instancia a `t3.small` (2 GB):
   ```bash
   # Desde tu máquina local
   aws ec2 stop-instances --instance-ids i-0653d60eb42b952d4
   aws ec2 modify-instance-attribute --instance-id i-0653d60eb42b952d4 --instance-type t3.small
   aws ec2 start-instances --instance-ids i-0653d60eb42b952d4
   ```

3. Haz el build, luego vuelve a `t3.micro` si quieres ahorrar costos.

4. **Alternativa:** Build localmente en tu máquina y sube las imágenes:
   ```bash
   # En tu máquina local
   docker build -t muni-backend:local ./Muni-backend
   docker save muni-backend:local | gzip > backend.tar.gz
   scp -i keypairs/transportes_floresV.pem backend.tar.gz ubuntu@44.204.104.240:/tmp/
   
   # En la EC2
   docker load < /tmp/backend.tar.gz
   ```

### Problema: Migraciones Prisma fallan

**Síntoma:**
```
Migration `xxx` failed to apply cleanly to the shadow database.
```

**Solución:**
1. Verificar que el usuario RDS tiene permisos para crear/alterar tablas.
2. Si es la primera vez, las migraciones deberían aplicarse automáticamente.
3. Aplicar migraciones manualmente:
   ```bash
   sudo docker exec -it app-backend-1 sh
   npx prisma migrate deploy
   exit
   ```

### Problema: Redis no responde

**Síntoma:**
```
Error: connect ECONNREFUSED redis:6379
```

**Solución:**
1. Verificar que Redis esté corriendo:
   ```bash
   sudo docker ps | grep redis
   ```

2. Verificar que el backend esté en la misma red Docker:
   ```bash
   sudo docker inspect app-backend-1 | grep NetworkMode
   # Debe ser: tfv-network
   ```

3. Probar conexión:
   ```bash
   sudo docker exec app-backend-1 ping redis
   ```

---

## 12. Limpieza y Mantenimiento

### Ver espacio en disco

```bash
df -h
sudo docker system df
```

### Limpiar imágenes antiguas

```bash
sudo docker image prune -a
```

### Ver logs de todos los servicios

```bash
cd /opt/app
sudo docker compose logs -f
```

### Reiniciar un servicio específico

```bash
sudo docker compose restart backend
```

### Parar todo el stack

```bash
cd /opt/app
sudo docker compose down
```

### Parar y eliminar volúmenes (⚠️ borra datos de Redis)

```bash
sudo docker compose down -v
```

---

## 13. Diferencias con Deploy por GHCR

| Aspecto | Deploy Manual (este doc) | Deploy con GHCR |
|---------|-------------------------|-----------------|
| **Build** | En la EC2 | En GitHub Actions |
| **Imágenes** | Locales (tag `:local`) | Publicadas en GHCR |
| **Actualizaciones** | `git pull` + rebuild | `docker pull` |
| **Requiere** | Código fuente en EC2 | Solo docker-compose.yml |
| **Velocidad despliegue** | Más lento (rebuild) | Más rápido (pull) |
| **Espacio disco** | Mayor (código + imágenes) | Menor (solo imágenes) |
| **Permisos GitHub** | No necesarios | Necesita acceso a Packages |

---

## 14. Checklist de Deploy

Antes de dar por completado el deploy, verifica:

- [ ] Terraform aplicado (infraestructura creada)
- [ ] Ansible ejecutado (Docker instalado, `.env` generado)
- [ ] Repos clonados en `/home/ubuntu/apps/`
- [ ] `docker-compose.yml` modificado con rutas correctas
- [ ] Build de backend exitoso
- [ ] Build de frontend exitoso (con `VITE_API_BASE_URL` correcta)
- [ ] Stack levantado (`docker compose up -d`)
- [ ] 3 contenedores corriendo y `healthy`
- [ ] Backend conecta a RDS (ver logs, no hay error de DB)
- [ ] Backend conecta a Redis (no hay error ECONNREFUSED)
- [ ] Frontend accesible en `http://IP:8080`
- [ ] API accesible en `http://IP:3000/api-docs`
- [ ] No hay errores CORS en consola del navegador
- [ ] Script `/opt/app/deploy.sh` creado y funcional

---

## Resumen de Comandos Rápidos

```bash
# Conectar a EC2
ssh -i keypairs/transportes_floresV.pem ubuntu@44.204.104.240

# Deploy completo (primera vez)
mkdir -p /home/ubuntu/apps && cd /home/ubuntu/apps
git clone https://github.com/TU-ORG/Muni-backend.git
git clone https://github.com/TU-ORG/Muni-front.git
# Editar /opt/app/docker-compose.yml (rutas + VITE_API_BASE_URL)
cd /opt/app
sudo docker compose build --no-cache
sudo docker compose up -d

# Ver estado
sudo docker ps
sudo docker compose logs -f

# Actualizar después de cambios
cd /home/ubuntu/apps/Muni-backend && git pull
cd /home/ubuntu/apps/Muni-front && git pull
cd /opt/app
sudo docker compose down
sudo docker compose build --no-cache
sudo docker compose up -d

# O usar el script
sudo /opt/app/deploy.sh
```

---

**Documentación complementaria:**
- [`README.md`](README.md) - Guía de infraestructura con Terraform y Ansible
- [`VERIFICACION.md`](VERIFICACION.md) - Checklist completo de integración

**¿Necesitas ayuda?** Revisa la sección de Troubleshooting o los logs de Docker.
