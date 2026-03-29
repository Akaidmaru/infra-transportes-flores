output "ec2_public_ip" {
  description = "IP pública de la EC2 (SSH 22)"
  value       = aws_instance.production.public_ip
}

output "tfv_public_api_url" {
  description = "URL base del API (HTTP demo; mismo valor que inyecta Ansible en el .env)"
  value       = "http://${aws_instance.production.public_ip}:3000"
}

output "tfv_frontend_url" {
  description = "URL del front nginx (HTTP estándar, puerto 80)"
  value       = "http://${aws_instance.production.public_ip}"
}

output "ec2_id" {
  description = "ID de la instancia EC2"
  value       = aws_instance.production.id
}

output "rds_endpoint" {
  description = "Hostname PostgreSQL (RDS)"
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Puerto PostgreSQL"
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Nombre de la base inicial"
  value       = aws_db_instance.main.db_name
}

output "s3_bucket_name" {
  description = "Bucket S3 para la app"
  value       = aws_s3_bucket.app.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.app.arn
}
