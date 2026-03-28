variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "keypair_name" {
  description = "Nombre del key pair para SSH (archivo <ssh_pem_relative_dir>/<nombre>.pem en la raíz del repo)"
  type        = string
}

variable "ssh_pem_relative_dir" {
  description = "Carpeta en la raíz del repo infra donde está el .pem (Ansible usa ../<dir>/ desde ansible/). Ej.: keypair o keypairs"
  type        = string
  default     = "keypairs"
}

variable "vpc_cidr" {
  description = "CIDR de la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "Subnet pública AZ A (EC2)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "Subnet pública AZ B (segunda AZ para RDS)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_a" {
  description = "AZ de la EC2 y primera subnet del DB group"
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_b" {
  description = "AZ distinta (segunda subnet del DB group)"
  type        = string
  default     = "us-east-1b"
}

variable "instance_type" {
  description = "EC2. En cuentas solo Free Tier suele aceptarse t3.micro (t2.micro a veces ya no es elegible)."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "AMI Ubuntu (us-east-1)"
  type        = string
  default     = "ami-0866a3c8686eaeeba"
}

variable "s3_bucket_suffix" {
  description = "Sufijo del nombre del bucket S3"
  type        = string
  default     = "app"
}

variable "db_username" {
  description = "Usuario administrador PostgreSQL (RDS)"
  type        = string
  default     = "tfvadmin"
}

variable "db_password" {
  description = "Contraseña maestra RDS (definir en terraform.tfvars)"
  type        = string
  sensitive   = true
}

variable "db_engine_version" {
  description = "Versión del motor PostgreSQL"
  type        = string
  default     = "16.4"
}

variable "db_allocated_storage" {
  description = "Almacenamiento RDS (GB)"
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "Clase de instancia RDS (p. ej. db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_backup_retention_period" {
  description = "Días de retención de backups automáticos. En cuenta AWS Free Tier suele exigirse 0 (sin backups continuos PITR)."
  type        = number
  default     = 0
}

variable "rds_publicly_accessible" {
  description = "Si es true, el endpoint RDS es alcanzable desde Internet (además del SG)"
  type        = bool
  default     = true
}

variable "rds_ingress_cidr" {
  description = "IPv4 permitidas al puerto 5432 (0.0.0.0/0 = cualquiera; restringe en producción)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "rds_allow_ipv6" {
  description = "Permitir PostgreSQL desde ::/0"
  type        = bool
  default     = true
}

variable "tfv_backend_image" {
  description = "Imagen Docker del API en GHCR (minúsculas), p. ej. ghcr.io/org/muni-backend:latest"
  type        = string
}

variable "tfv_frontend_image" {
  description = "Imagen Docker del front en GHCR (minúsculas), p. ej. ghcr.io/org/muni-frontend:latest"
  type        = string
}
