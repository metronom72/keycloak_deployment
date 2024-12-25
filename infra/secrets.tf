resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project}-${terraform.workspace}-db-credentials-21834eb2d53904f4332d2471cb424e75"
  description = "Database credentials for ${var.project} in ${terraform.workspace}"
  recovery_window_in_days = 0

  tags = {
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

resource "aws_secretsmanager_secret" "keycloak_admin" {
  name        = "${var.project}-${terraform.workspace}-keycloak-admin-8f412c8df6212c366640563fd0d298bb"
  description = "Keycloak admin credentials for ${var.project} in ${terraform.workspace}"
  recovery_window_in_days = 0

  tags = {
    Project     = var.project
    Environment = terraform.workspace
  }
}

resource "aws_secretsmanager_secret_version" "keycloak_admin_version" {
  secret_id = aws_secretsmanager_secret.keycloak_admin.id
  secret_string = jsonencode({
    username = var.keycloak_admin_username
    password = var.keycloak_admin_password
  })
}
