# 🚀 Flujo de Deploy Automatizado

Este documento describe el flujo completamente automatizado para deployar cambios en producción.

---

## 📊 Flujo Completo (Automatizado)

```
1. Desarrollador hace cambios
   ├─ Backend: Modifica código en feature/JMMB17
   └─ Frontend: Modifica código en refactor/structure
          ↓
2. Git push
   git push origin feature/JMMB17  (backend)
   git push origin refactor/structure  (frontend)
          ↓
3. GitHub Actions AUTOMÁTICO
   ├─ Compila backend → Publica en GHCR (~2-3 min)
   └─ Compila frontend → Publica en GHCR (~2-3 min)
          ↓
4. Deploy a EC2 (Manual o Automático)
   Opción A: Click en repo infra → Actions → "Auto-Deploy"
   Opción B: Ansible local (como antes)
          ↓
5. ✅ Aplicación desplegada en EC2
   - Frontend: http://44.212.48.142
   - API: http://44.212.48.142:3000
   - Swagger: http://44.212.48.142:3000/api-docs
```

---

## ⚡ Cambios vs Flujo Anterior

| Aspecto | Flujo Anterior | Flujo Automatizado |
|---------|----------------|-------------------|
| **Compilar backend** | Manual (click en Actions) | ✅ Automático en push |
| **Compilar frontend** | Manual (click en Actions) | ✅ Automático en push |
| **Deploy a EC2** | Ansible local | GitHub Actions (click) |
| **Tiempo total** | Push → Click → Click → Ansible (5-10 min) | Push → Click deploy (2-3 min) |
| **Sin Ansible local** | ❌ Requiere Ansible instalado | ✅ Todo desde GitHub |

---

## 🔧 Configuración Única (Solo una vez)

### **Backend**: https://github.com/Akaidmaru/Muni-backend-deploy/settings/secrets/actions

No requiere configuración adicional. El workflow ya está listo.

---

### **Frontend**: https://github.com/Akaidmaru/Muni-frontend-deploy/settings/secrets/actions

**Secret requerido:**
- `VITE_API_BASE_URL` = `http://44.212.48.142:3000`

---

### **Infra**: https://github.com/Akaidmaru/infra-transportes-flores/settings

#### **Secrets:**

1. `EC2_SSH_PRIVATE_KEY` = Contenido del archivo `.pem`
   ```bash
   cat /home/akaidmaru/Documents/projects/floresvargas/infra-transportes-flores/keypair/transportes_floresV.pem
   ```

2. `EC2_HOST` = `44.212.48.142`

3. `DB_USER` = `tfvadmin`

4. `DB_PASSWORD` = `floresvargas-2026`

5. `RDS_HOST` = `tfv-produccion.c6zwy2260qhw.us-east-1.rds.amazonaws.com`

6. `RDS_PORT` = `5432`

7. `RDS_DBNAME` = `tfvapp`

8. `JWT_SECRET` = (tu JWT secret del vault)

9. `S3_BUCKET` = `transportes-flores-vargas-720951496462-app`

#### **Variables:**

1. `BACKEND_IMAGE` = `ghcr.io/akaidmaru/muni-backend-deploy:latest`

2. `FRONTEND_IMAGE` = `ghcr.io/akaidmaru/muni-frontend-deploy:latest`

---

## 🎯 Uso Diario

### **Escenario 1: Cambio en el Backend**

```bash
cd /home/akaidmaru/Documents/projects/floresvargas/Muni-backend

# 1. Hacer cambios en el código
vim src/auth/auth.controller.ts

# 2. Commit y push
git add .
git commit -m "feat: nueva funcionalidad"
git push origin feature/JMMB17
```

**Resultado automático:**
- ✅ GitHub Actions compila el backend (2-3 min)
- ✅ Publica la imagen en GHCR
- ⏳ Esperas a que termine (verifica en Actions)

**Luego, deploy manual:**
1. Ve a https://github.com/Akaidmaru/infra-transportes-flores/actions
2. Click en **"Auto-Deploy on Image Update"**
3. Click **"Run workflow"**
4. Espera ~1-2 min
5. ✅ Backend desplegado

---

### **Escenario 2: Cambio en el Frontend**

```bash
cd /home/akaidmaru/Documents/projects/floresvargas/Muni-front

# 1. Hacer cambios
vim src/views/HomeView.vue

# 2. Commit y push
git add .
git commit -m "feat: mejorar UI"
git push origin refactor/structure
```

**Resultado automático:**
- ✅ GitHub Actions compila el frontend (2-3 min)
- ✅ Publica la imagen en GHCR

**Luego, deploy manual:**
1. Ve a https://github.com/Akaidmaru/infra-transportes-flores/actions
2. Click en **"Auto-Deploy on Image Update"**
3. Desmarca "Redesplegar backend" (solo frontend)
4. Click **"Run workflow"**
5. ✅ Frontend desplegado

---

### **Escenario 3: Cambios en Backend Y Frontend**

```bash
# Push ambos repos
git push origin feature/JMMB17  # backend
git push origin refactor/structure  # frontend
```

**Resultado:**
- ✅ Ambos workflows compilarán en paralelo (2-3 min cada uno)
- ⏳ Espera a que ambos terminen
- Luego ejecuta **"Auto-Deploy"** para redesplegar todo

---

## 🔄 Deploy Selectivo

El workflow `auto-deploy.yml` te permite elegir qué redesplegar:

- ✅ Solo backend
- ✅ Solo frontend
- ✅ Ambos (por defecto)

Útil si solo cambiaste uno de los dos.

---

## 🆚 Comparación con Ansible Local

| Aspecto | Ansible Local | GitHub Actions |
|---------|---------------|----------------|
| **Requiere instalado** | Python, Ansible, SSH | Nada |
| **Vault password** | Sí, cada vez | No (secretos en GitHub) |
| **Dónde corre** | Tu máquina | Runners de GitHub |
| **Velocidad** | 2-3 min | 1-2 min |
| **Desde cualquier lugar** | ❌ Solo con Ansible instalado | ✅ Desde navegador |
| **Historial** | ❌ Local | ✅ En GitHub Actions |

---

## ✅ Recomendación

**Para desarrollo diario**: Usa el flujo automatizado  
**Para debugging**: Usa Ansible local si necesitas más control

---

## 🐛 Troubleshooting

### Workflow de backend/frontend falla

1. Verifica logs en Actions
2. Revisa que el Dockerfile sea correcto
3. Re-ejecuta manualmente si fue un error temporal de red

### Deploy falla en EC2

1. Verifica que los secretos en el repo infra estén correctos
2. Verifica que la EC2 esté corriendo
3. Verifica que los Security Groups permitan SSH (puerto 22)

### Imágenes no se actualizan

1. Verifica que el workflow de backend/frontend terminó exitosamente ✅
2. Verifica que la imagen en GHCR tenga el tag correcto (`latest`)
3. Ejecuta el workflow de deploy nuevamente

---

## 📋 Checklist de Configuración

- [ ] Backend: workflow activado en push a `feature/JMMB17`
- [ ] Frontend: workflow activado en push a `refactor/structure` + secret `VITE_API_BASE_URL`
- [ ] Infra: 9 secretos configurados
- [ ] Infra: 2 variables configuradas
- [ ] Test: Push al backend → Verifica que se compile automáticamente
- [ ] Test: Push al frontend → Verifica que se compile automáticamente
- [ ] Test: Ejecuta "Auto-Deploy" → Verifica que despliegue correctamente

---

**¡Listo! Ahora tienes un flujo CI/CD completamente automatizado. 🚀**
