# 🚀 Guía Rápida: Configurar HTTPS con Cloudflare

**Tu dominio:** vectiaq.cl  
**IP EC2:** 44.212.48.142  
**Tiempo estimado:** 10 minutos

---

## Paso 1: Cloudflare DNS (2 minutos)

1. Ve a [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Selecciona tu dominio: **vectiaq.cl**
3. Click en **DNS** → **Records**
4. Click **Add record**:
   - **Type:** A
   - **Name:** @ (para el dominio raíz)
   - **IPv4 address:** `44.212.48.142`
   - **Proxy status:** 🟠 **Proxied** ← ¡Activa el proxy!
   - **TTL:** Auto
5. Click **Save**

### SSL/TLS

1. Ve a **SSL/TLS** → **Overview**
2. Selecciona: **Flexible**
3. Ve a **SSL/TLS** → **Edge Certificates**
4. Activa: **Always Use HTTPS**

---

## Paso 2: Terraform (5 minutos)

### A. Crear archivo de configuración

```bash
cd /home/akaidmaru/Documents/projects/floresvargas/infra-transportes-flores/terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### B. Configurar tu dominio

Busca la línea `app_domain` y cambia:

```hcl
app_domain = "vectiaq.cl"
```

Guarda el archivo (Ctrl+O, Enter, Ctrl+X).

### C. Aplicar cambios

```bash
terraform apply
```

Revisa los cambios y escribe `yes`.

Esto actualizará el archivo `ansible/ansible_inventory` con el nuevo CORS:
```
tfv_cors_origin="http://44.212.48.142,http://vectiaq.cl,https://vectiaq.cl"
```

---

## Paso 3: Re-deploy (3 minutos)

### Opción A: GitHub Actions (recomendado)

1. Ve a: `https://github.com/akaidmaru/infra-transportes-flores`
2. Click en **Actions**
3. Selecciona **Deploy to EC2**
4. Click **Run workflow** → **Run workflow**
5. Espera ~2 minutos

### Opción B: Ansible Manual

```bash
cd /home/akaidmaru/Documents/projects/floresvargas/infra-transportes-flores/ansible
ansible-playbook -i ansible_inventory ec2provisioning.yml --ask-vault-pass
```

---

## Paso 4: Probar (1 minuto)

Abre en tu navegador:

```
https://vectiaq.cl
```

Debería cargar tu aplicación con HTTPS! 🎉

---

## ⚠️ Problema: "Mixed Content"

Si ves errores en la consola del navegador tipo:

```
Mixed Content: The page at 'https://vectiaq.cl' was loaded over HTTPS,
but requested an insecure resource 'http://44.212.48.142:3000/...'
```

**Solución:** Crear un subdominio para el API.

### Crear subdominio API

1. En Cloudflare DNS, agrega otro registro:
   - **Type:** A
   - **Name:** api
   - **IPv4:** `44.212.48.142`
   - **Proxy:** 🟠 Proxied
   - **Save**

2. Actualizar frontend para usar `https://api.vectiaq.cl`:

   **En GitHub:**
   - Repo: `Muni-frontend-deploy`
   - Settings → Secrets → `VITE_API_BASE_URL`
   - Cambiar a: `https://api.vectiaq.cl`

3. Re-build frontend:
   - Actions → "Publish to GHCR" → Run workflow

4. Re-deploy:
   - En `infra-transportes-flores`
   - Actions → "Deploy to EC2" → Run workflow

---

## Verificación

### DNS propagado

```bash
nslookup vectiaq.cl
# Debería mostrar IPs de Cloudflare (104.26.x.x o 172.67.x.x)
```

### Backend funcionando

```bash
curl http://44.212.48.142:3000/api-docs
# Debería devolver HTML del Swagger
```

### Frontend carga

```bash
curl -I https://vectiaq.cl
# HTTP/2 200
# server: cloudflare
```

### No hay errores CORS

Abre `https://vectiaq.cl` → F12 → Console  
No deberían aparecer errores de CORS.

---

## Troubleshooting

### "DNS_PROBE_FINISHED_NXDOMAIN"

**Causa:** DNS aún no propagado  
**Solución:** Espera 5-10 minutos

### Error 520 (Cloudflare)

**Causa:** Tu EC2 no responde  
**Solución:**
```bash
ssh ubuntu@44.212.48.142
sudo docker ps  # Verificar contenedores corriendo
sudo docker logs app-frontend
sudo docker logs app-backend
```

### CORS Error

**Causa:** Backend no permite el origen  
**Solución:**
```bash
ssh ubuntu@44.212.48.142
sudo docker exec app-backend env | grep CORS_ORIGIN
# Debe incluir: https://vectiaq.cl
```

Si no lo incluye, verifica que aplicaste `terraform apply` y re-deployaste.

---

## Resumen de URLs

| Servicio | URL | Estado |
|----------|-----|--------|
| Frontend | https://vectiaq.cl | ✅ |
| Backend | http://44.212.48.142:3000 | ⚠️ Mixed content |
| API Subdomain | https://api.vectiaq.cl | 🎯 Recomendado |
| Swagger | https://api.vectiaq.cl/api-docs | 📚 |

---

**¿Preguntas?** Revisa `CONFIGURAR-DOMINIO.md` para la guía completa.
