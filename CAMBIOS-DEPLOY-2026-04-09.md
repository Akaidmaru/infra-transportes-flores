# Resumen de Cambios - Deploy Actualizado
**Fecha:** 9 de abril de 2026  
**Objetivo:** Actualizar repos de deploy con cambios de `Refactor/BR` y configurar nuevas variables de entorno

---

## 1. Merges Realizados

### Backend (`Muni-backend-deploy`)
- ✅ **Merge:** `old-origin/Refactor/BR` → `feature/JMMB17`
- **Sin conflictos**
- **Push:** Commit `bd59253`
- **Cambios incorporados:**
  - Nuevo módulo `vehicle-maintenance-record` (mantenimiento vehicular)
  - Servicio S3 (`s3.service.ts`) para firmas digitales
  - Trip history points (puntos GPS de viajes)
  - Eliminación de tablas de rutas (migración Prisma)
  - Actualización de dependencias npm

### Frontend (`Muni-frontend-deploy`)
- ✅ **Merge:** `old-origin/Refactor/BR` → `refactor/structure`
- **Conflicto resuelto:** `.env.example` (API URL + Google Maps)
- **Push:** Commit `111fbb6`
- **Cambios incorporados:**
  - Nuevas vistas de mantenimiento vehicular (`AdminMaintenanceView.vue`)
  - Componente `TripRouteMap.vue` (Google Maps)
  - Actualización de dependencias

### Infra (`infra-transportes-flores`)
- ℹ️ No había rama `Refactor/BR` en el repo original de infra
- Tu rama `main` local ya contenía `old-origin/main` + tus commits de deploy

---

## 2. Configuración de Variables de Entorno

### 2.1. Backend (`.env-example` actualizado)

**Nuevas variables agregadas:**
```env
# Rate limiting y verificación
VERIFICATION_RATE_LIMIT_SECONDS=60

# AWS S3 (firmas digitales) - NOMBRES CORREGIDOS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_S3_BUCKET=                    # Antes era AWS_S3_BUCKET_NAME
AWS_S3_SIGNED_URL_TTL=3600

# Google Maps (backend - geocoding)
GOOGLE_MAPS_API_KEY=

# Brevo (emails de verificación)
BREVO_API_KEY=
BREVO_SENDER_EMAIL=
BREVO_SENDER_NAME=
```

### 2.2. Frontend (Dockerfile y workflow)

**Build-time vars agregadas:**
```dockerfile
ARG VITE_GOOGLE_MAPS_API_KEY=
ENV VITE_GOOGLE_MAPS_API_KEY=${VITE_GOOGLE_MAPS_API_KEY}

ARG VITE_GOOGLE_MAPS_MAP_ID=DEMO_MAP_ID
ENV VITE_GOOGLE_MAPS_MAP_ID=${VITE_GOOGLE_MAPS_MAP_ID}
```

**Workflow `publish-ghcr.yml`:**
- Ahora valida `VITE_GOOGLE_MAPS_API_KEY` (además de `VITE_API_BASE_URL`)
- El build falla si no están configurados

### 2.3. Infra - Workflows de GitHub Actions

**Archivos actualizados:**
- `.github/workflows/deploy.yml`
- `.github/workflows/auto-deploy.yml`

**Cambios principales:**
```yaml
# Antes (no funcionaba)
image: ${{ vars.BACKEND_IMAGE }}

# Ahora (hardcoded en env del job)
env:
  BACKEND_IMAGE: ghcr.io/akaidmaru/muni-backend-deploy:latest
  FRONTEND_IMAGE: ghcr.io/akaidmaru/muni-frontend-deploy:latest

# Variables de entorno del contenedor backend agregadas:
environment:
  CORS_ORIGIN: "${{ secrets.CORS_ORIGIN }}"
  VERIFICATION_RATE_LIMIT_SECONDS: "60"
  GOOGLE_MAPS_API_KEY: "${{ secrets.GOOGLE_MAPS_API_KEY }}"
  BREVO_API_KEY: "${{ secrets.BREVO_API_KEY }}"
  BREVO_SENDER_EMAIL: "${{ secrets.BREVO_SENDER_EMAIL }}"
  BREVO_SENDER_NAME: "${{ secrets.BREVO_SENDER_NAME }}"
  AWS_ACCESS_KEY_ID: "${{ secrets.AWS_ACCESS_KEY_ID }}"
  AWS_SECRET_ACCESS_KEY: "${{ secrets.AWS_SECRET_ACCESS_KEY }}"
  AWS_S3_BUCKET: "${{ secrets.S3_BUCKET }}"
  AWS_S3_SIGNED_URL_TTL: "3600"
```

**Corrección crítica:** `AWS_S3_BUCKET_NAME` → `AWS_S3_BUCKET` (el código Nest usa este nombre)

### 2.4. Infra - Ansible

**Archivos actualizados:**
- `ansible/roles/deploy_stack/templates/docker-compose-ghcr.yml.j2`
- `ansible/roles/app_env/templates/env.j2`
- `ansible/vault.example.yml`
- `ansible/group_vars/production.yml`

**Variables nuevas en `vault.yml`:**
```yaml
# AWS IAM (S3)
tfv_aws_access_key_id: "AKIA..."
tfv_aws_secret_access_key: "..."

# Brevo (emails)
tfv_brevo_api_key: "xkeysib-..."
tfv_brevo_sender_email: "crolwh12@gmail.com"
tfv_brevo_sender_name: "TransportApp"

# Google Maps
tfv_google_maps_api_key: "AIza..."
# tfv_google_maps_map_id: "DEMO_MAP_ID"  # Solo para build local
```

**Variables en `production.yml`:**
```yaml
tfv_verification_code_ttl: 600
tfv_verification_rate_limit_seconds: 60
tfv_aws_s3_signed_url_ttl: 3600
```

---

## 3. Fixes Técnicos

### 3.1. Case-sensitivity en imágenes (Frontend)
**Problema:** Build fallaba en Docker porque el código importaba:
```js
import dailyMaintenanceIcon from '@/assets/images/admin/tareas-diarias.png'
```

Pero la carpeta se llamaba `Admin` (mayúscula).

**Solución:** Renombrar `Admin` → `admin`
- Commit: `111fbb6`

### 3.2. Variables de GitHub Actions
**Problema:** `vars.BACKEND_IMAGE` y `vars.FRONTEND_IMAGE` estaban vacías.

**Solución:** Hardcodear en `env` del job en lugar de usar repository variables.

---

## 4. Secretos Configurados en GitHub

### Repo: `infra-transportes-flores`

#### Secrets (Settings → Secrets and variables → Actions → Secrets)

| Secret | Valor | Uso |
|--------|-------|-----|
| `CORS_ORIGIN` | `http://IP_EC2` | Orígenes permitidos para CORS |
| `GOOGLE_MAPS_API_KEY` | `AIza...` | API de Google Maps (backend) |
| `BREVO_API_KEY` | `xkeysib-...` | Envío de emails |
| `BREVO_SENDER_EMAIL` | `crolwh12@gmail.com` | Email remitente |
| `BREVO_SENDER_NAME` | `TransportApp` | Nombre visible |
| `AWS_ACCESS_KEY_ID` | `AKIA...` | IAM con acceso S3 |
| `AWS_SECRET_ACCESS_KEY` | `***` | Secret key IAM |
| `S3_BUCKET` | `transportes-flores-vargas-...` | Bucket para firmas |
| `AWS_S3_BUCKET` | (opcional, duplicado) | Mismo que S3_BUCKET |
| `AWS_S3_SIGNED_URL_TTL` | (opcional) | TTL hardcoded en workflow |

**Secretos existentes (ya configurados antes):**
- `EC2_SSH_PRIVATE_KEY`, `EC2_HOST`
- `DB_USER`, `DB_PASSWORD`, `RDS_HOST`, `RDS_PORT`, `RDS_DBNAME`
- `JWT_SECRET`

### Repo: `Muni-frontend-deploy`

#### Secrets

| Secret | Valor |
|--------|-------|
| `VITE_API_BASE_URL` | `http://IP_EC2:3000` |
| `VITE_GOOGLE_MAPS_API_KEY` | `AIza...` (misma que backend) |

---

## 5. Commits Realizados

### Backend
```
bd59253 - docs(env): alinear .env-example con Nest (S3, Brevo, rate limit, CORS)
55eb2cb - Merge remote-tracking branch 'old-origin/Refactor/BR' into feature/JMMB17
```

### Frontend
```
111fbb6 - fix(assets): renombrar Admin → admin (case-sensitive para build Docker)
b5a52db - ci(docker): Vite Google Maps en build GHCR; validar VITE_GOOGLE_MAPS_API_KEY
f46fa8c - Merge old-origin/Refactor/BR; resolve .env.example (API URL + Google Maps vars)
```

### Infra
```
15dcf3c - fix(ci): usar env en lugar de vars para BACKEND_IMAGE y FRONTEND_IMAGE (hardcodeado)
4fe043d - ci: agregar debug para verificar variables BACKEND_IMAGE y FRONTEND_IMAGE
7b9538c - fix(deploy): AWS_S3_BUCKET y credenciales S3; Brevo, Maps y CORS en compose y Actions
```

---

## 6. Flujo de Deploy Actualizado

### Opción A: GitHub Actions (recomendado)

1. **Push a backend** (`feature/JMMB17`) → Workflow "Publish to GHCR" compila imagen
2. **Push a frontend** (`refactor/structure`) → Workflow "Publish to GHCR" compila imagen (necesita `VITE_API_BASE_URL` y `VITE_GOOGLE_MAPS_API_KEY`)
3. **Trigger manual:** `infra-transportes-flores` → Actions → "Deploy to EC2"
   - Pull de imágenes GHCR
   - Genera `docker-compose.yml` con todos los secretos
   - Sube a EC2 por SSH
   - `docker compose up -d`

### Opción B: Ansible (local)

```bash
cd ansible
ansible-playbook -i ansible_inventory ec2provisioning.yml --ask-vault-pass
```

**Requisitos:**
- `vault.yml` con las variables AWS, Brevo, Maps
- Inventario generado por Terraform con RDS, S3, CORS, etc.

---

## 7. Verificación Post-Deploy

### En EC2 (SSH)

```bash
# Ver logs del backend
sudo docker logs app-backend

# Verificar variables de entorno
sudo docker exec app-backend env | grep -E 'AWS_|BREVO_|GOOGLE_MAPS|CORS'

# Estado de contenedores
sudo docker ps

# Logs del frontend
sudo docker logs app-frontend
```

**Variables que deben aparecer:**
```
AWS_ACCESS_KEY_ID=AKIA...
AWS_SECRET_ACCESS_KEY=***
AWS_S3_BUCKET=transportes-flores-vargas-...
BREVO_API_KEY=xkeysib-...
GOOGLE_MAPS_API_KEY=AIza...
CORS_ORIGIN=http://IP
VERIFICATION_RATE_LIMIT_SECONDS=60
```

### URLs de acceso

- **Frontend:** `http://IP_EC2`
- **API:** `http://IP_EC2:3000`
- **Swagger:** `http://IP_EC2:3000/api-docs`

---

## 8. Seguridad - IMPORTANTE

⚠️ **Las credenciales expuestas en el chat deben rotarse:**

1. **AWS IAM:** Crear un nuevo usuario IAM con permisos solo para el bucket S3, revocar el anterior
2. **Brevo:** Regenerar API key en el dashboard de Brevo
3. **Google Maps:** Restringir la API key por referrer/IP en Google Cloud Console
4. **JWT Secret:** Cambiar en vault y GitHub Secrets (requiere re-login de usuarios)
5. **GitHub Token:** Regenerar Personal Access Token si fue expuesto

---

## 9. Archivos Modificados (Resumen)

### Backend
- `.env-example`

### Frontend
- `Dockerfile`
- `.github/workflows/publish-ghcr.yml`
- `.env.example`
- `src/assets/images/Admin/` → `src/assets/images/admin/` (rename)

### Infra
- `.github/workflows/deploy.yml`
- `.github/workflows/auto-deploy.yml`
- `ansible/roles/deploy_stack/templates/docker-compose-ghcr.yml.j2`
- `ansible/roles/deploy_stack/templates/docker-compose-local.yml.j2`
- `ansible/roles/deploy_stack/files/frontend.Dockerfile`
- `ansible/roles/app_env/templates/env.j2`
- `ansible/vault.example.yml`
- `ansible/group_vars/production.yml`

---

## 10. Próximos Pasos

- [ ] Disparar workflow "Deploy to EC2" en GitHub
- [ ] Verificar que backend y frontend levanten correctamente
- [ ] Probar funcionalidad de firmas (S3)
- [ ] Probar envío de emails (Brevo)
- [ ] Verificar mapas en el frontend
- [ ] Rotar credenciales expuestas
- [ ] Ejecutar migraciones Prisma en el servidor (`npx prisma migrate deploy`)

---

**Autor:** Asistente AI  
**Repo principal:** `infra-transportes-flores`  
**Repos de deploy:** `Muni-backend-deploy`, `Muni-frontend-deploy`
