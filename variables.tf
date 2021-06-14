variable "region" {
  default     = "us-east-2"
  description = "AWS region"
}

variable "db_instanceclass" {
  default     = "db.t3.micro"
  description = "AWS instance class to use"
}

variable "db_rootuser" {
  default = "root"
  description = "RDS root user"
}

variable "db_password" {
  description = "RDS root user password"
  sensitive   = true
}

variable "prefix" {
    description = "prefix prepended to names of all resources created"
    default = "terraform-rds-education"
}

variable "database" {
  type=map(string)
  description = "database variables"
  default = {
    username = "edu"
    password = "kij737hf"
    name = "test"
  }
}

