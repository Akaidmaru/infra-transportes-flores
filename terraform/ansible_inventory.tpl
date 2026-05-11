# Generado por Terraform (terraform apply). Stack: Vue + Nest (Node), RDS PostgreSQL.
# EC2: SSH 22. RDS: puerto 5432 (Postgres, no JVM).
# Inventario multi-entorno: production/dev/test.

%{ for env, host in environment_hosts ~}
[${env}]
${env}_server ansible_host=${host.public_ip} ansible_user=${host.ssh_user} ansible_connection=ssh ansible_port=22 tfv_rds_host=${host.rds_address} tfv_rds_port=${host.rds_port} tfv_rds_dbname=${host.db_name} tfv_s3_bucket=${host.s3_bucket} tfv_public_api_url="${host.tfv_public_api_url}" tfv_cors_origin="${host.tfv_cors_origin}" tfv_frontend_url="${host.tfv_frontend_url}" tfv_backend_image="${host.tfv_backend_image}" tfv_frontend_image="${host.tfv_frontend_image}"

[${env}:vars]
ansible_ssh_private_key_file=${private_key_path}

%{ endfor ~}
