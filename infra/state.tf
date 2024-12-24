terraform {
  backend "s3" {
    bucket         = "keycloak-terraform-state-9420629187"
    key            = "state/terraform.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    kms_key_id     = "alias/keycloak-terraform-bucket-key"
    dynamodb_table = "keycloak-terraform-state"
  }
}

# resource "aws_kms_key" "terraform_bucket_key" {
#   description             = "This key is used to encrypt bucket objects"
#   deletion_window_in_days = 10
#   enable_key_rotation     = true
#
#   tags = {
#     Name        = "${var.project}-terraform-state"
#     Project     = var.project
#   }
# }
#
# resource "aws_kms_alias" "key-alias" {
#   name          = "alias/keycloak-terraform-bucket-key"
#   target_key_id = aws_kms_key.terraform_bucket_key.key_id
# }
#
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = "keycloak-terraform-state-9420629187"
#
#   tags = {
#     Name        = "${var.project}-terraform-state"
#     Project     = var.project
#   }
# }
#
# resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
#   bucket = aws_s3_bucket.terraform_state.id
#
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "aws:kms"
#       kms_master_key_id = aws_kms_key.terraform_bucket_key.arn
#     }
#   }
# }
#
#
# resource "aws_dynamodb_table" "terraform_state" {
#   name           = "keycloak-terraform-state"
#   read_capacity  = 20
#   write_capacity = 20
#   hash_key       = "LockID"
#
#   attribute {
#     name = "LockID"
#     type = "S"
#   }
#
#   tags = {
#     Name        = "${var.project}-terraform-state"
#     Project     = var.project
#   }
# }
