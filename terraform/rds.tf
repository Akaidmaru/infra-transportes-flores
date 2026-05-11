resource "aws_db_subnet_group" "main" {
  name       = "tfv-db-subnet"
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "tfv-db-subnet"
  }
}

resource "aws_db_instance" "env" {
  for_each = var.environments

  identifier     = "tfv-${each.key}"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = each.value.db_instance_class

  allocated_storage = each.value.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = each.value.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible          = var.rds_publicly_accessible
  multi_az                     = false
  backup_retention_period      = var.db_backup_retention_period
  skip_final_snapshot          = true
  deletion_protection          = false
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  performance_insights_enabled = false

  tags = {
    Name        = "tfv-rds-${each.key}"
    Environment = each.key
  }
}
