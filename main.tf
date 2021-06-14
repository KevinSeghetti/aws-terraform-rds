provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name                 = "${var.prefix}-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_db_subnet_group" "education" {
  name       = "${var.prefix}-rds-subnet-group"
  subnet_ids = module.vpc.public_subnets

  tags = {
    Name = "${var.prefix}-rds-subnet-group"
  }
}

resource "aws_security_group" "rds" {
  name   = "${var.prefix}-rds-sg"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.prefix}-rds"
  }
}

resource "aws_db_parameter_group" "education" {
  name   = "${var.prefix}-rds-parameter-group"
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_db_instance" "education" {
  identifier             = "${var.prefix}-rds-instance"
  instance_class         = "db.t3.micro"
  allocated_storage      = 100
  engine                 = "postgres"
  engine_version         = "13.1"
  username               = var.db_rootuser
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.education.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}

# kts TODO: if the DB becomes uncontactable (say, it is full)
# then it becomes impossible to run this script, since it
# tries to contact it to fetch this data
# either need a way to tell terraform these go in phases
# or split this out into a separate terraform config

# Setup PostgreSQL Provider After RDS Database is Provisioned
provider "postgresql" {
    host            = "${aws_db_instance.education.address}"
    port            = 5432
    username        = var.db_rootuser
    password        = var.db_password
    superuser       = false
}
# Create App User
resource "postgresql_role" "application_role" {
    name                = var.database.username
    login               = true
    password            = var.database.password
    encrypted_password  = true
}
# Create Database
resource "postgresql_database" "dev_db" {
    name              = var.database.name
    owner             = var.database.username
    template          = "template0"
    lc_collate        = "C"
    connection_limit  = -1
    allow_connections = true
}

