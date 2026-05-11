output "ec2_public_ip" {
  description = "IP pública de cada EC2 por entorno"
  value       = { for env, instance in aws_instance.env : env => instance.public_ip }
}

output "tfv_public_api_url" {
  description = "URL base del API por entorno (HTTP demo; mismo valor que inyecta Ansible)"
  value       = { for env, instance in aws_instance.env : env => "http://${instance.public_ip}:3000" }
}

output "tfv_frontend_url" {
  description = "URL del frontend por entorno (custom si app_frontend_url está definido)"
  value = {
    for env, instance in aws_instance.env :
    env => trimspace(var.environments[env].app_frontend_url) != "" ? var.environments[env].app_frontend_url : "http://${instance.public_ip}"
  }
}

output "ec2_id" {
  description = "ID de cada instancia EC2 por entorno"
  value       = { for env, instance in aws_instance.env : env => instance.id }
}

output "rds_endpoint" {
  description = "Hostname PostgreSQL (RDS) por entorno"
  value       = { for env, db in aws_db_instance.env : env => db.address }
}

output "rds_port" {
  description = "Puerto PostgreSQL por entorno"
  value       = { for env, db in aws_db_instance.env : env => db.port }
}

output "rds_database_name" {
  description = "Nombre de la base inicial por entorno"
  value       = { for env, db in aws_db_instance.env : env => db.db_name }
}

output "s3_bucket_name" {
  description = "Bucket S3 para la app"
  value       = aws_s3_bucket.app.id
}

output "s3_bucket_arn" {
  description = "ARN del bucket S3"
  value       = aws_s3_bucket.app.arn
}
