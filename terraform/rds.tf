resource "aws_db_subnet_group" "main" {
  name       = "tfv-db-subnet"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "tfv-db-subnet"
  }
}

resource "aws_db_instance" "main" {
  identifier     = "tfv-produccion"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = "tfvapp"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible          = var.rds_publicly_accessible
  multi_az                     = false
  backup_retention_period      = 7
  skip_final_snapshot          = true
  deletion_protection          = false
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  performance_insights_enabled = false

  tags = {
    Name = "tfv-rds-produccion"
  }
}
