# Reporte de Verificación de Integración
**Fecha:** 28 de marzo de 2026  
**Estado de Infraestructura:** Desplegada previamente (backup disponible)

---

## 1. Estado de la Infraestructura AWS (Terraform)

### ✅ Configuración Verificada

**Archivo:** `terraform/terraform.tfvars`
- ✅ Key pair: `transportes_floresV`
- ✅ Región: `us-east-1`
- ✅ Tipo de instancia: `t3.micro` (Free Tier compatible para cuentas nuevas)
- ✅ Zonas de disponibilidad: `us-east-1a` y `us-east-1b`
- ✅ Password RDS: `floresvargas-2026`
- ✅ Imágenes GHCR definidas:
  - Backend: `ghcr.io/floresvargas/muni-backend:latest`
  - Frontend: `ghcr.io/floresvargas/muni-frontend:latest`

**Outputs del último despliegue (desde backup):**
```json
{
  "ec2_id": "i-0653d60eb42b952d4",
  "ec2_public_ip": "44.204.104.240",
  "rds_endpoint": "tfv-produccion.c6zwy2260qhw.us-east-1.rds.amazonaws.com",
  "rds_port": 5432,
  "rds_database_name": "tfvapp",
  "s3_bucket_name": "transportes-flores-vargas-720951496462-app"
}
```

### ⚠️ Acción Requerida

1. **Estado Terraform vacío**: El archivo `terraform.tfstate` está vacío (recursos destruidos o limpiados)
   - **Solución**: Ejecutar `terraform apply` para regenerar la infraestructura
   - Esto creará: VPC, subnets, EC2, RDS, S3, Security Groups, IAM roles

2. **Inventario Ansible**: No existe `ansible/ansible_inventory`
   - **Causa**: Se genera automáticamente en `terraform apply`
   - **Contendrá**: IP EC2, datos RDS, bucket S3, URLs (`:3000` y `:8080`), imágenes GHCR

---

## 2. Credenciales y Secretos

### ✅ Vault de Ansible

- ✅ Archivo `ansible/vault.yml` existe y está cifrado con `ansible-vault`
- ✅ Archivo `.vault_pass.txt` existe (necesario para descifrado)

### ⚠️ Sincronización Crítica

**Debe verificarse manualmente** que `vault.yml` contenga:

```yaml
tfv_db_user: "tfvadmin"  # Debe coincidir con db_username de Terraform (default)
tfv_db_password: "floresvargas-2026"  # DEBE COINCIDIR EXACTAMENTE con terraform.tfvars
tfv_jwt_secret: "<secreto_largo_aleatorio>"  # Para NestJS JWT
```

**Comando para verificar:**
```bash
cd ansible
ansible-vault view vault.yml --vault-password-file=.vault_pass.txt
```

**⚠️ CRÍTICO**: Si los passwords de RDS no coinciden, el backend no podrá conectarse a la base de datos.

---

## 3. Backend (NestJS) - Verificación de Código

### ✅ Variables de Entorno

**Archivo:** `src/main.ts`
- ✅ Puerto: Lee `process.env.PORT` (default 3000) - línea 36
- ✅ CORS: Lee `process.env.CORS_ORIGIN`, hace split por comas - línea 9
- ✅ Swagger: Configurado en `/api-docs` - línea 34

**Archivo:** `src/prisma/prisma.service.ts`
- ✅ DATABASE_URL: Lee `process.env.DATABASE_URL` - línea 12
- ✅ Usa PrismaAdapter para PostgreSQL

**Archivo:** `src/redis/redis.module.ts`
- ✅ REDIS_URL: Lee `process.env.REDIS_URL` con fallback a `localhost:6379` - línea 10

### ✅ Dockerfile Backend

**Archivo:** `Muni-backend/Dockerfile`
- ✅ Multi-stage build (build + runner)
- ✅ Usuario no root (`node`) - línea 31
- ✅ ENV `NODE_ENV=production` y `PORT=3000` - líneas 16-17
- ✅ HEALTHCHECK contra `/api-docs` - líneas 36-37
- ✅ CMD ejecuta migraciones Prisma y arranca app - línea 39
- ✅ Labels OCI para identificación

### ✅ .dockerignore Backend

- ✅ Excluye: `node_modules`, `dist`, `.git`, `.env`, tests, configs ESLint/Prettier
- ✅ Excluye: `.github` (workflows no van en la imagen)

### ✅ Workflows Backend

**CI (`ci.yml`):**
- ✅ Se ejecuta en push/PR a main/master
- ✅ Solo hace `docker build` (valida Dockerfile)
- ✅ No publica ni despliega

**Publish (`publish-ghcr.yml`):**
- ✅ Manual (`workflow_dispatch`)
- ✅ Publica a GHCR con tags `:latest` y `:sha`
- ✅ Usa nombre del repo en minúsculas automáticamente

---

## 4. Frontend (Vue + Vite) - Verificación de Código

### ✅ Variables de Entorno en Build

**Archivo:** `src/services/axios.js`
- ✅ baseURL: `import.meta.env.VITE_API_BASE_URL` - línea 5
- ✅ withCredentials: `true` (permite cookies/auth) - línea 6
- ✅ Interceptor JWT: Agrega `Authorization: Bearer` desde localStorage - líneas 13-19

### ✅ Dockerfile Frontend

**Archivo:** `Muni-front/Dockerfile`
- ✅ Multi-stage build (build Node + runtime nginx)
- ✅ ARG `VITE_API_BASE_URL` con default `localhost:3000` - línea 12
- ✅ Build de Vite embebe la variable en bundle estático - línea 15
- ✅ nginx con wget para HEALTHCHECK - líneas 22, 27-28
- ✅ Labels OCI

### ✅ nginx.conf

**Archivo:** `Muni-front/nginx.conf`
- ✅ Listen 80, server_name `_` (cualquier host)
- ✅ `try_files` para Vue Router (SPA) - línea 14
- ✅ Cache para `/assets/` (Vite hash) - líneas 17-19
- ✅ Gzip habilitado - líneas 9-11
- ✅ Header de seguridad `X-Content-Type-Options` - línea 12

**✅ Configuración correcta para el setup actual:**
- No hace proxy al backend (correcto: front en :8080, API en :3000 separados)
- El navegador llama directamente a `http://IP:3000` desde el bundle

### ✅ Workflows Frontend

**CI (`ci.yml`):**
- ✅ Se ejecuta en push/PR
- ✅ Hace `docker build` con `VITE_API_BASE_URL` desde secret (opcional)
- ✅ Fallback a `http://127.0.0.1:3000` si no hay secret (solo para validación)

**Publish (`publish-ghcr.yml`):**
- ✅ Manual (`workflow_dispatch`)
- ✅ **Valida que existe `secrets.VITE_API_BASE_URL`** - líneas 19-26
- ✅ Pasa build-arg al Docker - línea 42
- ✅ Publica con tags `:latest` y `:sha`

### ⚠️ Acción Requerida en GitHub

**Repo Muni-front → Settings → Secrets and variables → Actions:**

Crear secret:
```
Nombre: VITE_API_BASE_URL
Valor: http://44.204.104.240:3000
```

**Sin este secret:**
- ❌ El workflow "Publish to GHCR" fallará
- ❌ La imagen no tendrá la URL correcta del API
- ❌ El frontend no podrá comunicarse con el backend en producción

---

## 5. Docker Compose y Ansible

### ✅ Docker Compose

**Archivo:** `docker/docker-compose.yml`

Servicios:
1. **redis** (puerto interno 6379)
   - ✅ Imagen: `redis:7-alpine`
   - ✅ Red: `tfv-network`

2. **backend** (puerto host 3000)
   - ✅ Imagen desde variable `TFV_BACKEND_IMAGE`
   - ✅ Lee `.env` generado por Ansible
   - ✅ `depends_on: redis`
   - ✅ Red: `tfv-network`

3. **frontend** (puerto host 8080)
   - ✅ Imagen desde variable `TFV_FRONTEND_IMAGE`
   - ✅ `depends_on: backend`
   - ✅ Red: `tfv-network`

**✅ Arquitectura de red correcta:**
- Backend puede resolver `redis:6379` por nombre de servicio
- Frontend y backend en la misma red pero puertos expuestos separados
- Usuario accede a front en `:8080`, front llama a API en `:3000`

### ✅ Template de Ansible

**Archivo:** `ansible/roles/app_env/templates/env.j2`

Variables que se inyectan en `/opt/app/.env`:
- ✅ `DATABASE_URL` - construido desde inventario (RDS) + vault (credenciales)
- ✅ `JWT_SECRET` - desde vault
- ✅ `CORS_ORIGIN` - desde inventario (inyectado por Terraform con IP)
- ✅ `REDIS_URL=redis://redis:6379` - hardcoded (correcto para Docker)
- ✅ `S3_BUCKET` - desde inventario
- ✅ `TFV_BACKEND_IMAGE` y `TFV_FRONTEND_IMAGE` - desde inventario
- ✅ Variables opcionales: Brevo, Google Maps (condicionales)

**✅ Template del inventario actualizado:**

**Archivo:** `terraform/ansible_inventory.tpl`
- ✅ Inyecta IP en `tfv_public_api_url="http://IP:3000"`
- ✅ Inyecta IP en `tfv_cors_origin="http://IP:8080"`
- ✅ Incluye variables RDS (host, port, dbname)
- ✅ Incluye bucket S3
- ✅ Incluye imágenes GHCR desde `terraform.tfvars`

### ✅ Playbook de Ansible

**Archivo:** `ansible/ec2provisioning.yml`

Roles ejecutados (en orden):
1. ✅ `basic_setup` - Configuración base del sistema
2. ✅ `update_os` - Actualización de paquetes
3. ✅ `nodejs` - Instala Node 20 LTS
4. ✅ `app_env` - Genera `/opt/app/.env` desde template
5. ✅ `docker` - Instala Docker y copia `docker-compose.yml`
6. ✅ `deploy_stack` - Ejecuta `docker compose pull && up -d`

**Pre-tasks (validaciones):**
- ✅ Verifica que inventario tenga variables de Terraform
- ✅ Verifica que vault tenga secretos (db_user, db_password, jwt_secret)
- ✅ Verifica que inventario tenga URLs e imágenes

---

## 6. Puertos y Networking

### ✅ Security Groups (Terraform)

**Archivo:** `terraform/security-group.tf`

**EC2 (entrada):**
- ✅ SSH: 22 (IPv4 + IPv6)
- ✅ HTTP: 80 (IPv4 + IPv6)
- ✅ HTTPS: 443 (IPv4 + IPv6)
- ✅ API: 3000 (IPv4 + IPv6)
- ✅ Front: 8080 (IPv4 + IPv6)

**RDS (entrada):**
- ✅ PostgreSQL: 5432 desde EC2 (security group reference)
- ✅ PostgreSQL: 5432 desde `rds_ingress_cidr` (configurable, default `0.0.0.0/0`)

### ✅ Mapeo de Puertos

| Servicio | Puerto Container | Puerto Host EC2 | Acceso Público |
|----------|-----------------|----------------|----------------|
| Frontend nginx | 80 | 8080 | ✅ Sí (SG permite) |
| Backend NestJS | 3000 | 3000 | ✅ Sí (SG permite) |
| Redis | 6379 | - | ❌ No (solo red Docker interna) |

**URLs de acceso:**
- Front: `http://44.204.104.240:8080`
- API: `http://44.204.104.240:3000`
- Swagger: `http://44.204.104.240:3000/api-docs`

---

## 7. CORS - Verificación de Coherencia

### ✅ Configuración Backend

**Origen permitido (generado por Ansible):**
```
CORS_ORIGIN=http://44.204.104.240:8080
```

**Código en `main.ts` (líneas 9-17):**
```typescript
const allowedOrigins = process.env.CORS_ORIGIN?.split(',') || ['http://localhost:5173'];
app.enableCors({
  origin: allowedOrigins,
  credentials: true,
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
  allowedHeaders: 'Content-Type,Authorization',
});
```

✅ Permite múltiples orígenes separados por coma
✅ Permite credenciales (cookies, auth)
✅ Headers y métodos correctos

### ✅ Configuración Frontend

**axios.js:**
```javascript
withCredentials: true  // Envía cookies en requests CORS
```

**✅ Validación:**
- Origen del front: `http://44.204.104.240:8080`
- Backend permite ese origen exacto
- Puerto diferente (8080 vs 3000) = CORS necesario ✅
- Misma IP = misma máquina pero distinto origen (por puerto) ✅

---

## 8. Healthchecks

### ✅ Backend

**Dockerfile líneas 36-37:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://127.0.0.1:'+(process.env.PORT||3000)+'/api-docs',..."
```

- ✅ Verifica endpoint Swagger (`/api-docs`)
- ✅ Usa puerto dinámico desde `PORT` env
- ✅ Tiempo de inicio: 40s (permite migraciones Prisma)

### ✅ Frontend

**Dockerfile líneas 27-28:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null || exit 1
```

- ✅ Verifica nginx responde en raíz
- ✅ Inicio rápido (5s, no necesita migraciones)

**Validación en EC2:**
```bash
docker ps  # Columna STATUS debe mostrar "healthy"
```

---

## 9. Resumen de Acciones Pendientes

### 🔴 ALTA PRIORIDAD (Bloqueantes)

1. **Terraform Apply**
   ```bash
   cd terraform
   terraform apply
   ```
   - Regenera infraestructura AWS
   - Crea `ansible_inventory` automáticamente con IPs y datos

2. **Verificar Vault**
   ```bash
   cd ansible
   ansible-vault view vault.yml --vault-password-file=.vault_pass.txt
   ```
   - Confirmar que `tfv_db_password: "floresvargas-2026"` coincide con Terraform
   - Confirmar que `tfv_jwt_secret` esté definido

3. **GitHub Secret (Muni-front)**
   - Repo → Settings → Secrets and variables → Actions
   - Crear: `VITE_API_BASE_URL` = `http://44.204.104.240:3000`

4. **Publicar Imágenes GHCR**
   - Repo Muni-backend → Actions → "Publish to GHCR" → Run workflow
   - Repo Muni-front → Actions → "Publish to GHCR" → Run workflow
   - Verificar en GitHub Packages que aparezcan las imágenes

5. **Visibilidad de Paquetes GHCR**
   - Opción A: Hacer públicos los paquetes (GitHub → Package settings)
   - Opción B: `docker login ghcr.io` en EC2 con PAT (si privados)

### 🟡 DESPUÉS DEL DESPLIEGUE

6. **Ansible Playbook**
   ```bash
   cd ansible
   ansible-playbook -i ansible_inventory ec2provisioning.yml --ask-vault-pass
   ```
   - Instala Docker, Node, genera `.env`, ejecuta `docker compose up`

7. **Validación en EC2**
   ```bash
   ssh -i ../keypairs/transportes_floresV.pem ubuntu@44.204.104.240
   cd /opt/app
   cat .env  # Verificar variables correctas
   docker ps  # Ver contenedores healthy
   docker logs backend  # Ver logs de migraciones y arranque
   curl http://localhost:3000/api-docs  # Swagger responde
   ```

8. **Pruebas de Integración**
   - Navegador: `http://44.204.104.240:8080` (frontend)
   - Navegador: `http://44.204.104.240:3000/api-docs` (Swagger)
   - Consola navegador: verificar que requests a API no den error CORS

---

## 10. Diagrama de Dependencias

```mermaid
graph TD
    TF[terraform apply] -->|genera| INV[ansible_inventory]
    TF -->|crea| AWS[EC2 + RDS + S3]
    
    VAULT[vault.yml] -->|secretos| ANS[ansible-playbook]
    INV -->|variables| ANS
    
    GH_BACK[Workflow Backend] -->|publica| GHCR_BACK[ghcr.io/.../muni-backend]
    GH_FRONT[Workflow Frontend] -->|publica| GHCR_FRONT[ghcr.io/.../muni-frontend]
    
    SECRET[GitHub Secret<br/>VITE_API_BASE_URL] -->|build-arg| GH_FRONT
    
    ANS -->|genera| ENV[/opt/app/.env]
    GHCR_BACK -->|docker pull| DC[docker compose up]
    GHCR_FRONT -->|docker pull| DC
    ENV -->|variables| DC
    
    DC -->|inicia| CONTAINERS[Redis + Backend + Frontend]
    CONTAINERS -->|conecta| AWS
    
    style TF fill:#e1f5ff
    style VAULT fill:#ffe1e1
    style SECRET fill:#fff4e1
    style CONTAINERS fill:#e1ffe1
```

---

## 11. Checklist Final

Antes de dar por completada la integración:

- [ ] Terraform state tiene recursos (no vacío)
- [ ] `ansible_inventory` existe y contiene IP correcta
- [ ] Vault descifrado muestra passwords coincidentes
- [ ] Secret `VITE_API_BASE_URL` existe en GitHub (repo front)
- [ ] Imagen backend publicada en GHCR
- [ ] Imagen frontend publicada en GHCR (con URL correcta)
- [ ] Paquetes GHCR visibles/accesibles
- [ ] Ansible playbook ejecutado sin errores
- [ ] `docker ps` muestra 3 contenedores healthy
- [ ] Frontend carga en navegador (`:8080`)
- [ ] Swagger accesible (`:3000/api-docs`)
- [ ] No hay errores CORS en consola del navegador
- [ ] Backend puede ejecutar migraciones Prisma
- [ ] Backend conecta a RDS y Redis

---

## Conclusión

**Estado Actual:** ✅ Configuración validada y coherente

Todos los archivos de configuración (Dockerfiles, workflows, templates Ansible, compose) están correctamente alineados. La arquitectura es sólida:

- Backend y frontend en contenedores separados con puertos distintos
- CORS configurado correctamente para misma IP, puertos diferentes
- Variables de entorno fluyen correctamente: Terraform → Ansible → Docker
- Healthchecks implementados
- Workflows CI/CD separados (CI para validar, Publish para desplegar)
- Security groups permiten tráfico necesario

**Único impedimento:** La infraestructura AWS necesita ser re-desplegada (`terraform apply`) y las imágenes Docker deben publicarse en GHCR antes de ejecutar Ansible.
