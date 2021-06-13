terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.13.0"
    }


  }
}
