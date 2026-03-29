# Generado por Terraform (terraform apply). Stack: Vue + Nest (Node), RDS PostgreSQL.
# EC2: SSH 22. RDS: puerto ${rds_port} (Postgres, no JVM).
# URLs HTTP demo (misma IP): API :3000, front :80 (HTTP estándar) — imágenes desde terraform.tfvars

[production]
production_server ansible_host=${production_ip} ansible_user=${ssh_user} ansible_connection=ssh ansible_port=22 tfv_rds_host=${rds_address} tfv_rds_port=${rds_port} tfv_rds_dbname=${db_name} tfv_s3_bucket=${s3_bucket} tfv_public_api_url="http://${production_ip}:3000" tfv_cors_origin="http://${production_ip}" tfv_backend_image="${tfv_backend_image}" tfv_frontend_image="${tfv_frontend_image}"

[production:vars]
ansible_ssh_private_key_file=${private_key_path}
