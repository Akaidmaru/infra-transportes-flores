resource "aws_instance" "env" {
  for_each = var.environments

  ami                         = var.ami_id
  instance_type               = each.value.ec2_instance_type
  subnet_id                   = aws_subnet.public_a.id
  availability_zone           = var.availability_zone_a
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true
  key_name                    = var.keypair_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_app.name

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = false
  }

  depends_on = [
    aws_route_table_association.public_a,
  ]

  tags = {
    Name        = "tfv-ec2-${each.key}"
    Environment = each.key
  }
}

locals {
  ansible_environment_hosts = {
    for env, instance in aws_instance.env : env => {
      public_ip          = instance.public_ip
      ssh_user           = "ubuntu"
      rds_address        = aws_db_instance.env[env].address
      rds_port           = tostring(aws_db_instance.env[env].port)
      db_name            = aws_db_instance.env[env].db_name
      s3_bucket          = aws_s3_bucket.app.id
      tfv_backend_image  = trimspace(var.environments[env].backend_image) != "" ? var.environments[env].backend_image : var.tfv_backend_image
      tfv_frontend_image = trimspace(var.environments[env].frontend_image) != "" ? var.environments[env].frontend_image : var.tfv_frontend_image
      tfv_public_api_url = "http://${instance.public_ip}:3000"
      tfv_frontend_url   = trimspace(var.environments[env].app_frontend_url) != "" ? var.environments[env].app_frontend_url : "http://${instance.public_ip}"
      tfv_cors_origin = join(",", compact(concat(
        ["http://${instance.public_ip}"],
        trimspace(var.environments[env].app_domain) != "" ? [
          "http://${var.environments[env].app_domain}",
          "https://${var.environments[env].app_domain}",
          "https://www.${var.environments[env].app_domain}"
        ] : []
      )))
    }
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible_inventory.tpl", {
    environment_hosts = local.ansible_environment_hosts
    private_key_path  = "../${var.ssh_pem_relative_dir}/${var.keypair_name}.pem"
  })
  filename             = "../ansible/ansible_inventory"
  file_permission      = "0644"
  directory_permission = "0755"
}
