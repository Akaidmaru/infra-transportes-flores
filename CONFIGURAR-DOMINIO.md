# Configurar Dominio HTTPS con Cloudflare

**Fecha:** 10 de abril de 2026  
**Dominio:** vectiaq.cl  
**IP EC2:** 44.212.48.142

---

## 1. Cloudflare DNS

### Registros DNS a crear:

```
Type: A
Name: @
IPv4: 44.212.48.142
Proxy: 🟠 Proxied (activado)
TTL: Auto
```

*Opcional para www:*
```
Type: CNAME
Name: www
Target: vectiaq.cl
Proxy: 🟠 Proxied
```

### SSL/TLS Settings

1. **SSL/TLS** → **Overview** → Modo: **Flexible**
2. **SSL/TLS** → **Edge Certificates** → **Always Use HTTPS**: ON

---

## 2. Actualizar CORS en Backend

El backend debe permitir solicitudes desde `https://vectiaq.cl`.

### Opción A: GitHub Secrets (Recomendado)

1. Ve a: `https://github.com/akaidmaru/infra-transportes-flores`
2. **Settings** → **Secrets and variables** → **Actions** → **Secrets**
3. Edita `CORS_ORIGIN`:
   ```
   http://44.212.48.142,https://vectiaq.cl,http://vectiaq.cl
   ```
4. **Actions** → **Deploy to EC2** → **Run workflow**

### Opción B: Ansible Manual

1. Editar archivo local:
   ```bash
   cd /home/akaidmaru/Documents/projects/floresvargas/infra-transportes-flores
   nano ansible/ansible_inventory
   ```

2. Cambiar la línea `tfv_cors_origin`:
   ```
   tfv_cors_origin="http://44.212.48.142,https://vectiaq.cl,http://vectiaq.cl"
   ```

3. Re-deploy:
   ```bash
   cd ansible
   ansible-playbook -i ansible_inventory ec2provisioning.yml --ask-vault-pass
   ```

### Opción C: Terraform + Ansible (Permanente)

**Agregar variable en Terraform:**

1. Editar `terraform/variables.tf` y agregar:
   ```hcl
   variable "app_domain" {
     description = "Dominio principal de la aplicación"
     type        = string
     default     = ""
   }
   ```

2. Editar `terraform/ansible_inventory.tpl` línea 6:
   ```
   tfv_cors_origin="http://${production_ip}%{if app_domain != ""},%{for proto in ["http", "https"]}${proto}://${app_domain}%{if proto != "https"},%{endif}%{endfor}%{endif}"
   ```

3. Crear `terraform/terraform.tfvars`:
   ```hcl
   keypair_name = "transportes_floresV"
   db_password  = "TU_PASSWORD"
   
   tfv_backend_image  = "ghcr.io/akaidmaru/muni-backend-deploy:latest"
   tfv_frontend_image = "ghcr.io/akaidmaru/muni-frontend-deploy:latest"
   
   app_domain = "vectiaq.cl"
   ```

4. Aplicar cambios:
   ```bash
   cd terraform
   terraform apply -auto-approve
   
   cd ../ansible
   ansible-playbook -i ansible_inventory ec2provisioning.yml --ask-vault-pass
   ```

---

## 3. Actualizar Frontend (API URL)

El frontend también necesita saber dónde está el backend.

### Opción A: Backend en IP (más fácil)

No cambiar nada. El frontend sigue llamando a `http://44.212.48.142:3000`.

⚠️ **Problema:** Navegador bloqueará peticiones HTTPS → HTTP (mixed content)

### Opción B: Backend también con dominio (recomendado)

**Crear subdminio para API:**

En Cloudflare DNS:
```
Type: A
Name: api
IPv4: 44.212.48.142
Proxy: 🟠 Proxied
```

**Actualizar secrets del frontend:**

Repo: `Muni-frontend-deploy`
- Secret `VITE_API_BASE_URL`: `https://api.vectiaq.cl`

**Re-build y deploy del frontend:**
- Trigger workflow "Publish to GHCR" en frontend
- Trigger workflow "Deploy to EC2" en infra

---

## 4. Verificación

### Después de configurar DNS (esperar 1-5 min):

```bash
# Verificar propagación DNS
nslookup vectiaq.cl

# Debe mostrar:
# Non-authoritative answer:
# Name: vectiaq.cl
# Address: 104.26.x.x (IP de Cloudflare, no tu EC2)
```

### Después de re-deploy:

1. Abre: `https://vectiaq.cl`
2. Abre DevTools → Console
3. Verifica que no haya errores CORS

### Probar API:

```bash
# Si usas api.vectiaq.cl:
curl https://api.vectiaq.cl/api-docs

# Si usas IP:
curl http://44.212.48.142:3000/api-docs
```

---

## 5. (Opcional) Mejorar Seguridad - SSL Full

Una vez que todo funcione, puedes mejorar la seguridad:

1. **Instalar certificado SSL en EC2** (Let's Encrypt)
2. **Configurar Nginx como reverse proxy**
3. **Cambiar Cloudflare SSL/TLS a "Full (strict)"**

Esto requiere más pasos pero es más seguro (HTTPS end-to-end).

---

## URLs Finales

| Servicio | URL | Puerto |
|----------|-----|--------|
| **Frontend** | https://vectiaq.cl | 443 (Cloudflare) → 80 (EC2) |
| **Backend** | https://api.vectiaq.cl | 443 (Cloudflare) → 3000 (EC2) |
| **Swagger** | https://api.vectiaq.cl/api-docs | - |

---

## Troubleshooting

### "Mixed Content" error
El frontend HTTPS intenta llamar a backend HTTP. Solución: usar `api.vectiaq.cl`.

### CORS error después de cambiar dominio
Verifica que `CORS_ORIGIN` incluya `https://vectiaq.cl`.

### DNS no resuelve
Espera 5-10 minutos. Limpia caché DNS:
```bash
# Linux/Mac
sudo systemd-resolve --flush-caches

# Windows
ipconfig /flushdns
```

### Cloudflare muestra error 520
Tu EC2 no responde. Verifica:
```bash
ssh ubuntu@44.212.48.142
sudo docker ps
sudo docker logs app-frontend
sudo docker logs app-backend
```
