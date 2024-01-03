terraform {
  required_providers {
    aws = {
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}



data "aws_subnets" "private_subnets_id" {
  filter {
    name   = "tag:Name"
    values = [var.private_subnets_tagname]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

}

data "aws_s3_bucket" "airflow_bucket" {
  bucket = var.state_backetname
}

data "aws_subnets" "public_subnets_id" {
  filter {
    name   = "tag:Name"
    values = [var.public_subnets_tagname]
  }
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }

}