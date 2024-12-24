variable "project" {
  description = "The project Name where all resources will be launched."
  type = string
  default = "keycloak"
}

variable "environment" {
  description = "The environment name, defined in environments defined as a environment."
  type = string
  default = "development"
}

variable "region" {
  description = "The region to create resources."
  type = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.1.0.0/16"
}

variable "db_name" {
  description = "The name of the database snapshot."
  type        = string
}

variable "db_username" {
  description = "The username for the database."
  type        = string
}

variable "db_password" {
  description = "The password for the database."
  type        = string
}

variable "keycloak_admin_username" {
  description = "The username for the keycloak admin."
  type        = string
}

variable "keycloak_admin_password" {
  description = "The password for the keycloak admin."
  type        = string
}
