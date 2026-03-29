# Deploy Automático con GitHub Actions

Workflow que despliega automáticamente en EC2 cuando se activa manualmente desde GitHub.

## 🚀 Ventajas

- ✅ **Un solo click**: Deploy desde GitHub Actions
- ✅ **Sin Ansible local**: No necesitas ejecutar comandos en tu máquina
- ✅ **Rápido**: < 1 minuto (solo pull + up)
- ✅ **Trazabilidad**: Historial de deploys en GitHub

---

## 📋 Configuración de Secretos y Variables

Ve a tu repo de infra: https://github.com/Akaidmaru/infra-transportes-flores/settings

### **Secrets** (Settings → Secrets and variables → Actions → Secrets):

1. **`EC2_SSH_PRIVATE_KEY`**
   - Contenido del archivo `.pem`:
   ```bash
   cat /home/akaidmaru/Documents/projects/floresvargas/infra-transportes-flores/keypair/transportes_floresV.pem
   ```
   - Copia TODO el contenido (incluye `-----BEGIN RSA PRIVATE KEY-----` y `-----END RSA PRIVATE KEY-----`)

2. **`EC2_HOST`**
   - Valor: `44.212.48.142`

3. **`DB_USER`**
   - Valor: `tfvadmin` (del vault)

4. **`DB_PASSWORD`**
   - Valor: `floresvargas-2026` (del vault)

5. **`RDS_HOST`**
   - Valor: `tfv-produccion.c6zwy2260qhw.us-east-1.rds.amazonaws.com`

6. **`RDS_PORT`**
   - Valor: `5432`

7. **`RDS_DBNAME`**
   - Valor: `tfvapp`

8. **`JWT_SECRET`**
   - Valor: (el JWT del vault, el string largo)

9. **`S3_BUCKET`**
   - Valor: `transportes-flores-vargas-720951496462-app`

### **Variables** (Settings → Secrets and variables → Actions → Variables):

1. **`BACKEND_IMAGE`**
   - Valor: `ghcr.io/akaidmaru/muni-backend-deploy:latest`

2. **`FRONTEND_IMAGE`**
   - Valor: `ghcr.io/akaidmaru/muni-frontend-deploy:latest`

---

## 🚀 Uso del Workflow

### Deploy desde GitHub:

1. Ve a https://github.com/Akaidmaru/infra-transportes-flores/actions
2. Click en **"Deploy to EC2"**
3. Click **"Run workflow"**
4. Selecciona modo: `ghcr` (recomendado) o `local`
5. Click **"Run workflow"**
6. Espera < 1 minuto

---

## 🔄 Flujo Completo de Deploy

```
1. Código → Push a backend/frontend
   ↓
2. GitHub Actions compila → Publica en GHCR
   ↓
3. Repo infra → "Deploy to EC2" workflow
   ↓
4. GitHub Actions → SSH a EC2 → docker compose pull + up
   ↓
5. ✅ Aplicación desplegada
```

---

## 🎯 Comparación con Ansible Local

| Aspecto           | Ansible Local             | GitHub Actions |
|-------------------|---------------------------|----------------|
| **Comando**       | `ansible-playbook...`     | Click en GitHub |
| **Dónde corre**   | Tu máquina local          | Runners de GitHub |
| **Requiere**      | Python, Ansible, SSH      | Nada (todo en la nube) |
| **Vault**         | Necesita contraseña       | Secretos en GitHub |
| **Tiempo**        | ~2-3 min                  | < 1 min |

---

## ✅ Recomendación

Usa **GitHub Actions** para deploys rápidos desde cualquier lugar. Ansible local es útil solo para debugging o cuando GitHub está caído.
