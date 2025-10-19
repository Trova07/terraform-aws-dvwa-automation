data "aws_db_snapshot" "latest_snapshot" {
  snapshot_type          = "manual"
  db_instance_identifier = var.db_instance.identifier
  most_recent            = true
  include_public         = false
  include_shared         = false
}

resource "aws_db_subnet_group" "db" {
  name        = var.rds_subnet_group.name
  description = var.rds_subnet_group.description
  subnet_ids  = var.subnet_ids
}

resource "aws_db_instance" "db-instance" {
  depends_on     = [aws_db_subnet_group.db]
  engine         = var.db_instance.engine
  engine_version = var.db_instance.engine_version
  identifier     = var.db_instance.identifier

  username = var.db_instance.username
  password = var.db_instance.password

  instance_class    = var.db_instance.instance_class
  storage_type      = var.db_instance.storage_type
  allocated_storage = var.db_instance.allocated_storage
  multi_az          = var.db_instance.multi_az

  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [for name in var.db_instance.sg_names : var.sg_ids[name]]
  publicly_accessible    = var.db_instance.publicly_accessible

  snapshot_identifier = var.db_instance.latest_snapshot ? data.aws_db_snapshot.latest_snapshot.id : var.db_instance.snapshot_identifier

  skip_final_snapshot       = true
  deletion_protection       = false
  final_snapshot_identifier = "${var.db_instance.identifier}-${replace(timestamp(), ":", "-")}"

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}
