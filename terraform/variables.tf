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

variable "ami_id" {
  description = "AMI Ubuntu (us-east-1)"
  type        = string
  default     = "ami-0866a3c8686eaeeba"
}

variable "environments" {
  description = "Configuración por entorno (EC2 + RDS) para production/dev/test"
  type = map(object({
    ec2_instance_type    = string
    db_instance_class    = string
    db_allocated_storage = number
    db_name              = string
    app_domain           = optional(string, "")
    app_frontend_url     = optional(string, "")
    backend_image        = optional(string, "")
    frontend_image       = optional(string, "")
  }))
  default = {
    production = {
      ec2_instance_type    = "t3.micro"
      db_instance_class    = "db.t3.micro"
      db_allocated_storage = 20
      db_name              = "tfvapp"
      app_domain           = ""
      app_frontend_url     = ""
      backend_image        = ""
      frontend_image       = ""
    }
    dev = {
      ec2_instance_type    = "t3.micro"
      db_instance_class    = "db.t3.micro"
      db_allocated_storage = 20
      db_name              = "tfvappdev"
      app_domain           = ""
      app_frontend_url     = ""
      backend_image        = ""
      frontend_image       = ""
    }
    test = {
      ec2_instance_type    = "t3.micro"
      db_instance_class    = "db.t3.micro"
      db_allocated_storage = 20
      db_name              = "tfvapptest"
      app_domain           = ""
      app_frontend_url     = ""
      backend_image        = ""
      frontend_image       = ""
    }
  }
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

# Compatibilidad con terraform.tfvars anterior (ya no se usan en el modelo por entorno).
variable "instance_type" {
  description = "DEPRECADO: usar environments.<env>.ec2_instance_type"
  type        = string
  default     = null
}

variable "db_instance_class" {
  description = "DEPRECADO: usar environments.<env>.db_instance_class"
  type        = string
  default     = null
}

variable "db_allocated_storage" {
  description = "DEPRECADO: usar environments.<env>.db_allocated_storage"
  type        = number
  default     = null
}

variable "app_domain" {
  description = "DEPRECADO: usar environments.<env>.app_domain"
  type        = string
  default     = null
}

variable "app_frontend_url" {
  description = "DEPRECADO: usar environments.<env>.app_frontend_url"
  type        = string
  default     = null
}

