resource "aws_instance" "production" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
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
    Name        = "tfv-ec2-produccion"
    Environment = "demo"
  }
}

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible_inventory.tpl", {
    production_ip       = aws_instance.production.public_ip
    ssh_user            = "ubuntu"
    private_key_path    = "../${var.ssh_pem_relative_dir}/${var.keypair_name}.pem"
    rds_address         = aws_db_instance.main.address
    rds_port            = tostring(aws_db_instance.main.port)
    db_name             = aws_db_instance.main.db_name
    s3_bucket           = aws_s3_bucket.app.id
    tfv_backend_image   = var.tfv_backend_image
    tfv_frontend_image  = var.tfv_frontend_image
    app_domain          = var.app_domain
  })
  filename             = "../ansible/ansible_inventory"
  file_permission      = "0644"
  directory_permission = "0755"
}
