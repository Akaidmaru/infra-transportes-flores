variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "keypair_name" {
  description = "Nombre del key pair para SSH (archivo ../keypairs/<nombre>.pem)"
  type        = string
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
  description = "EC2 (p. ej. t2.micro para free tier)"
  type        = string
  default     = "t2.micro"
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
