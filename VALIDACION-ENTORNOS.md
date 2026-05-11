# Validacion EC2 + RDS por entorno

Checklist para confirmar que `production`, `dev` y `test` quedaron bien despues del refactor Terraform + Ansible.

## 1) Terraform

Desde `terraform/`:

```bash
terraform init
terraform plan
```

Esperado:

- `production` se conserva por `moved` blocks (sin destroy/recreate).
- Se crean recursos nuevos para `dev` y `test`:
  - `aws_instance.env["dev"]`
  - `aws_instance.env["test"]`
  - `aws_db_instance.env["dev"]`
  - `aws_db_instance.env["test"]`

Aplicar:

```bash
terraform apply
```

## 2) Inventario Ansible generado

Revisar `ansible/ansible_inventory` y confirmar:

- Existe grupo `[production]` con host `production_server`.
- Existe grupo `[dev]` con host `dev_server`.
- Existe grupo `[test]` con host `test_server`.
- Cada host tiene sus vars `tfv_rds_host`, `tfv_rds_port`, `tfv_rds_dbname`, `tfv_public_api_url`, `tfv_frontend_url`.

## 3) Outputs Terraform

Desde `terraform/`:

```bash
terraform output ec2_public_ip
terraform output rds_endpoint
terraform output tfv_public_api_url
```

Esperado: salida tipo mapa con claves `production`, `dev`, `test`.

## 4) Ansible por entorno

Desde `ansible/`:

```bash
ansible-playbook -i ansible_inventory ec2provisioning.yml -e tfv_target_group=dev
ansible-playbook -i ansible_inventory ec2provisioning.yml -e tfv_target_group=test
ansible-playbook -i ansible_inventory ec2provisioning.yml -e tfv_target_group=production
```

Esperado:

- Playbook corre contra el grupo indicado.
- Se genera `/opt/app/.env` con su RDS correspondiente.
- Stack docker levanta sin errores (`docker compose up -d`).

## 5) Prueba funcional minima

Para cada entorno:

- Front responde por su `tfv_frontend_url`.
- API responde por su `tfv_public_api_url`.
- Swagger disponible en `${tfv_public_api_url}/api-docs`.
- Backend conecta a su RDS (sin cruzarse entre entornos).
