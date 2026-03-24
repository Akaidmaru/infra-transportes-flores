# Generado por Terraform (terraform apply).
# EC2: SSH 22. RDS: PostgreSQL puerto ${rds_port}.

[production]
production_server ansible_host=${production_ip} ansible_user=${ssh_user} ansible_connection=ssh ansible_port=22 tfv_rds_host=${rds_address} tfv_rds_port=${rds_port} tfv_rds_dbname=${db_name}

[production:vars]
ansible_ssh_private_key_file=${private_key_path}
