# Guía: Deploy con GitHub Container Registry (GHCR)

Esta guía te muestra cómo compilar imágenes Docker en GitHub Actions (rápido, 2-3 min) y desplegarlas en EC2 usando `docker pull` (sin compilar localmente).

## ✅ Ventajas vs compilación local:
- ⚡ **Compilación rápida**: 2-3 minutos en GitHub vs 60+ minutos en t3.micro
- 💰 **Gratis**: 2,000 minutos/mes de GitHub Actions
- 🚀 **Deploy rápido**: Solo `docker pull` (< 1 minuto)
- 🔄 **Reproducible**: Mismas imágenes en cualquier entorno

---

## 📋 Paso 1: Configurar Secretos en GitHub

### Backend: `Muni-backend-deploy`

1. Ve a https://github.com/Akaidmaru/Muni-backend-deploy/settings/secrets/actions
2. Click en **"New repository secret"**
3. Agrega **NINGÚN secreto** (el backend no necesita secretos de build)

### Frontend: `Muni-frontend-deploy`

1. Ve a https://github.com/Akaidmaru/Muni-frontend-deploy/settings/secrets/actions
2. Click en **"New repository secret"**
3. Agrega:
   - **Name**: `VITE_API_BASE_URL`
   - **Value**: `http://44.212.48.142:3000`
   - Click **"Add secret"**

---

## 📋 Paso 2: Crear Personal Access Token (PAT) para GHCR

1. Ve a https://github.com/settings/tokens
2. Click en **"Generate new token"** → **"Generate new token (classic)"**
3. Configura:
   - **Note**: `GHCR Package Write`
   - **Expiration**: `90 days` (o lo que prefieras)
   - **Scopes**: 
     - ✅ `write:packages`
     - ✅ `read:packages`
     - ✅ `delete:packages` (opcional, para limpiar imágenes viejas)
4. Click **"Generate token"**
5. **Copia el token** (empieza con `ghp_...`)

---

## 📋 Paso 3: Configurar PAT en ambos repos

### Para Backend:
1. Ve a https://github.com/Akaidmaru/Muni-backend-deploy/settings/secrets/actions
2. Click **"New repository secret"**
3. Agrega:
   - **Name**: `GHCR_TOKEN`
   - **Value**: `<tu_token_ghp_...>`
   - Click **"Add secret"**

### Para Frontend:
1. Ve a https://github.com/Akaidmaru/Muni-frontend-deploy/settings/secrets/actions
2. Click **"New repository secret"**
3. Agrega:
   - **Name**: `GHCR_TOKEN`
   - **Value**: `<tu_token_ghp_...>` (el mismo)
   - Click **"Add secret"**

---

## 📋 Paso 4: Publicar Imágenes en GHCR

### Backend:
1. Ve a https://github.com/Akaidmaru/Muni-backend-deploy/actions
2. Click en **"Publish to GHCR"** (workflow)
3. Click **"Run workflow"** → Selecciona rama `feature/JMMB17` → **"Run workflow"**
4. Espera 2-3 minutos hasta que termine ✅

### Frontend:
1. Ve a https://github.com/Akaidmaru/Muni-frontend-deploy/actions
2. Click en **"Publish to GHCR"** (workflow)
3. Click **"Run workflow"** → Selecciona rama `refactor/structure` → **"Run workflow"**
4. Espera 2-3 minutos hasta que termine ✅

**Verifica las imágenes publicadas**:
- Backend: https://github.com/Akaidmaru?tab=packages&repo_name=Muni-backend-deploy
- Frontend: https://github.com/Akaidmaru?tab=packages&repo_name=Muni-frontend-deploy

---

## 📋 Paso 5: Hacer las imágenes públicas (opcional pero recomendado)

Para evitar autenticación al hacer `docker pull`:

### Backend:
1. Ve a https://github.com/users/Akaidmaru/packages/container/muni-backend-deploy/settings
2. Scroll hasta **"Danger Zone"**
3. Click **"Change visibility"** → Selecciona **"Public"** → Confirma

### Frontend:
1. Ve a https://github.com/users/Akaidmaru/packages/container/muni-frontend-deploy/settings
2. Scroll hasta **"Danger Zone"**
3. Click **"Change visibility"** → Selecciona **"Public"** → Confirma

---

## 📋 Paso 6: Deploy en EC2 con Ansible

Una vez publicadas las imágenes en GHCR, despliega en EC2:

```bash
cd /home/akaidmaru/Documents/projects/floresvargas/infra-transportes-flores/ansible

# Ejecutar Ansible en modo GHCR (por defecto):
ansible-playbook -i ansible_inventory ec2provisioning.yml --vault-password-file=.vault_pass.txt
```

Ansible automáticamente:
1. ✅ Detecta modo `ghcr` (por defecto)
2. ✅ Hace `docker compose pull` (< 1 minuto)
3. ✅ Levanta los contenedores con `docker compose up -d`

**URLs de acceso**:
- Frontend: http://44.212.48.142:8080
- API: http://44.212.48.142:3000
- Swagger: http://44.212.48.142:3000/api-docs

---

## 🔄 Flujo de Deploy Futuro

Para deploys futuros:

1. **Commit + Push** tus cambios:
   ```bash
   cd /home/akaidmaru/Documents/projects/floresvargas/Muni-backend-deploy
   git add .
   git commit -m "feat: nueva funcionalidad"
   git push origin feature/JMMB17
   ```

2. **Publicar imagen** (GitHub Actions):
   - Ve a Actions → "Publish to GHCR" → "Run workflow"
   - Espera 2-3 minutos

3. **Deploy en EC2** (Ansible):
   ```bash
   cd /home/akaidmaru/Documents/projects/floresvargas/infra-transportes-flores/ansible
   ansible-playbook -i ansible_inventory ec2provisioning.yml --vault-password-file=.vault_pass.txt
   ```

---

## 🐛 Troubleshooting

### Error: "unauthorized: authentication required"

Si las imágenes son **privadas**, necesitas autenticarte en EC2:

```bash
# Conéctate a la EC2:
ssh -i ../keypair/transportes_floresV.pem ubuntu@44.212.48.142

# Login a GHCR:
echo "<tu_token_ghp_...>" | docker login ghcr.io -u akaidmaru --password-stdin

# Vuelve a ejecutar Ansible
```

**Solución permanente**: Haz las imágenes públicas (Paso 5).

### Compilación local (fallback)

Si necesitas compilar localmente (no recomendado):

```bash
cd /home/akaidmaru/Documents/projects/floresvargas/infra-transportes-flores/ansible
ansible-playbook -i ansible_inventory ec2provisioning.yml --vault-password-file=.vault_pass.txt -e "tfv_deploy_mode=local"
```

---

## 📊 Comparación

| Aspecto                  | Compilación Local (t3.micro) | GHCR (GitHub Actions) |
|--------------------------|------------------------------|-----------------------|
| **Tiempo de compilación** | 60-90 minutos                | 2-3 minutos           |
| **Tiempo de deploy**      | 60-90 minutos                | < 1 minuto (pull)     |
| **CPU/RAM**               | 100% CPU, puede fallar       | 0% (compilación remota) |
| **Costo**                 | Gratis (Free Tier)           | Gratis (2,000 min/mes) |
| **Reproducibilidad**      | ❌ Depende del estado local  | ✅ Misma imagen siempre |

**Recomendación**: Siempre usa GHCR para deploys de producción.

---

## ✅ Checklist Final

- [ ] Secretos configurados en GitHub (frontend: `VITE_API_BASE_URL`, ambos: `GHCR_TOKEN`)
- [ ] PAT creado con permisos `write:packages`
- [ ] Workflows ejecutados exitosamente (backend + frontend)
- [ ] Imágenes publicadas en GHCR (visibles en Packages)
- [ ] Imágenes hechas públicas (opcional)
- [ ] Ansible ejecutado con modo `ghcr`
- [ ] Servicios corriendo en EC2 (verificar con `docker ps`)
- [ ] Frontend accesible: http://44.212.48.142:8080
- [ ] API accesible: http://44.212.48.142:3000/api-docs

---

**¡Listo! Ahora tienes un flujo de CI/CD profesional con GitHub Actions + GHCR. 🚀**
