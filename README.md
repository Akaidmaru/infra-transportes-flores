# Infraestructura — Transportes Flores Vargas

Este repositorio define la infraestructura en **AWS** con **Terraform** y el aprovisionamiento de la instancia de cómputo con **Ansible**. La aplicación (Vue + NestJS) se ejecuta en **Docker Compose** sobre una **EC2**; la base de datos es **RDS PostgreSQL**; hay un bucket **S3** para datos de la app.

## Qué se crea en AWS

| Recurso | Rol |
|--------|-----|
| **VPC, subnets, IGW, rutas** | Red aislada con salida a Internet |
| **EC2** (`t3.micro` por defecto) | Servidor donde corren Docker, front (puerto 8080) y API (3000) |
| **RDS PostgreSQL** | Base de datos gestionada |
| **S3** | Almacenamiento de objetos (nombre incluye el ID de cuenta) |
| **Security groups** | SSH 22, HTTP/S, 8080, 3000 en la EC2; Postgres desde la EC2 hacia RDS |
| **IAM** | Rol/perfil para que la EC2 acceda al bucket S3 |

Terraform también genera el fichero **`ansible/ansible_inventory`** con la IP pública, datos de RDS, bucket S3, URLs de API/CORS e imágenes **GHCR** definidas en `terraform.tfvars`.

## Prerrequisitos en tu máquina

- [Terraform](https://www.terraform.io/) ≥ 1.x
- [Ansible](https://docs.ansible.com/) (Python 3)
- Cuenta AWS con permisos para EC2, VPC, RDS, S3, IAM
- Par de claves **EC2** creado en la misma región que usarás (p. ej. `us-east-1`); la clave privada `.pem` debe estar en `keypairs/<nombre_del_par>.pem` (ver Terraform `keypair_name`)

## 1. Terraform

### 1.1 Configuración

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edita **`terraform.tfvars`** como mínimo:

- **`keypair_name`**: nombre exacto del key pair en EC2 (la clave privada debe ser `../keypairs/<keypair_name>.pem`).
- **`db_password`**: contraseña del usuario maestro de RDS.
- **`tfv_backend_image`** y **`tfv_frontend_image`**: URIs en **GHCR** en minúsculas (deben coincidir con lo que publiquen los workflows de GitHub Actions de los repos del backend y del front).

Opcional: `aws_region`, `instance_type` (en cuentas Free Tier recientes suele usarse `t3.micro`), `db_backup_retention_period` (en Free Tier a menudo `0`).

### 1.2 Despliegue

```bash
terraform init
terraform plan
terraform apply
```

Al terminar, anota los **outputs**:

- `ec2_public_ip` — SSH y URLs de demo
- `tfv_public_api_url` / `tfv_frontend_url` — mismas bases que inyecta el inventario
- `rds_endpoint`, `rds_port`, `rds_database_name`
- `s3_bucket_name`

Tras cada `apply` que cambie la IP o los datos de RDS, se regenera **`../ansible/ansible_inventory`**.

### 1.3 Free Tier y errores habituales

- Cuentas creadas **a partir del 15 de julio de 2025** suelen **no** permitir `t2.micro` en Free Tier; usa **`t3.micro`** (u otro tipo que marque AWS como free-tier-eligible).
- La retención de backups de RDS puede estar limitada: **`db_backup_retention_period = 0`** suele ser necesaria en Free Tier.
- El **key pair** debe existir en la región elegida; si no, `InvalidKeyPair.NotFound`.

## 2. Ansible

### 2.1 Secretos (`vault`)

```bash
cd ../ansible
cp vault.example.yml vault.yml
# Edita vault.yml y cifra (recomendado):
ansible-vault encrypt vault.yml
```

Define al menos:

| Variable | Debe coincidir con |
|----------|-------------------|
| **`tfv_db_user`** | Usuario RDS (`db_username` en Terraform; por defecto `tfvadmin`) |
| **`tfv_db_password`** | **`db_password`** de `terraform.tfvars` |
| **`tfv_jwt_secret`** | Secreto largo para JWT en NestJS |

Opcionales: claves Brevo, Google Maps, etc. (ver `vault.example.yml`).

Si usas vault cifrado:

```bash
ansible-playbook -i ansible_inventory ec2provisioning.yml --ask-vault-pass
```

O configura la contraseña en un fichero referenciado por Ansible (p. ej. `vault_password_file` en `ansible.cfg`); **no subas** ese fichero a Git (está en `.gitignore`).

### 2.2 Clave SSH

El inventario apunta a **`../keypairs/<keypair_name>.pem`**. Permisos recomendados:

```bash
chmod 400 ../keypairs/tu-clave.pem
```

### 2.3 Ejecutar el playbook

Desde el directorio **`ansible/`**:

```bash
ansible-playbook -i ansible_inventory ec2provisioning.yml
```

El playbook instala dependencias base, Node (referencia), escribe **`/opt/app/.env`**, instala Docker, copia **`docker-compose.yml`** y ejecuta **`docker compose pull && up`**.

## 3. Aplicaciones (repos aparte)

1. **Imágenes**: los workflows de GitHub Actions deben publicar en **GHCR** las mismas URIs que pusiste en **`tfv_backend_image`** y **`tfv_frontend_image`**.
2. **Front (Vite)**: en el repositorio del front, configura el variable **`VITE_API_BASE_URL`** (p. ej. `http://<IP_EC2>:3000`) igual que la URL pública del API (output `tfv_public_api_url` o el valor del inventario). Esa variable se usa **en el build** de la imagen.
3. **Registro en la EC2**: si las imágenes GHCR son **privadas**, en el servidor hará falta `docker login ghcr.io` (token con permiso `read:packages`) antes de que `docker compose pull` funcione; si son **públicas**, no hace falta.

## 4. Puertos y URLs (demo HTTP)

| Servicio | Puerto en el host |
|----------|-------------------|
| Front (nginx) | **8080** |
| API NestJS | **3000** |
| SSH | **22** |

- Front: `http://<IP_EC2>:8080`
- API: `http://<IP_EC2>:3000`
- CORS en el backend usa el origen del front (`http://<IP_EC2>:8080`), generado en el inventario.

## 5. Estructura del repositorio

```
infra-transportes-flores/
├── terraform/           # Infra AWS + generación de ansible_inventory
├── ansible/             # Playbook, roles, vault, group_vars
├── docker/              # docker-compose.yml copiado a /opt/app en la EC2
└── keypairs/            # Clave .pem (local; no versionar)
```

## 6. Orden recomendado (resumen)

1. Crear key pair en AWS y guardar el `.pem` en `keypairs/`.
2. Rellenar `terraform/terraform.tfvars` (contraseña RDS, imágenes GHCR, `keypair_name`).
3. `terraform apply`.
4. Preparar `ansible/vault.yml` alineado con RDS y JWT.
5. `ansible-playbook` desde `ansible/`.
6. Tener imágenes publicadas en GHCR y variable `VITE_API_BASE_URL` coherente en el front.

---

Para cambios solo de configuración en la EC2 (nuevo `.env` o nuevas imágenes), vuelve a ejecutar Terraform si cambian IP o RDS, actualiza vault si hace falta, y repite el playbook o solo el rol de despliegue según tu flujo.
