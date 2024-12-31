resource "aws_security_group" "rds_sg" {
  name        = "${var.project}-${terraform.workspace}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.keycloak.id

  ingress {
    description      = "Allow PostgreSQL traffic from ECS tasks"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    security_groups  = [aws_security_group.ecs_cluster_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-${terraform.workspace}-rds-sg"
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_db_instance" "postgres" {
  identifier              = "${var.project}-${terraform.workspace}-database"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "17.2"
  instance_class          = "db.t4g.micro"
  db_name                 = var.db_name
  username                = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string).username
  password                = jsondecode(aws_secretsmanager_secret_version.db_credentials_version.secret_string).password
  db_subnet_group_name    = aws_db_subnet_group.private_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id, aws_security_group.ecs_cluster_sg.id]
  publicly_accessible     = false
  skip_final_snapshot     = false
  deletion_protection     = true
  final_snapshot_identifier = "${var.project}-${terraform.workspace}-database-final-snapshot"
  copy_tags_to_snapshot     = true

  tags = {
    Name        = "${var.project}-${terraform.workspace}-rds-db-instance"
    Project     = var.project
    Environment = terraform.workspace
  }
}
