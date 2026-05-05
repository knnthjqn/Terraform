variable "project_name" {
  type = string
  default = "test-stack"
}

variable "environment" {
  type = string
  default = "prod"
}

variable "region" {
  type = string
  default = "ap-southeast-1"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "db_instance_class" {
  type = string
  default = "db.t4g.micro"
}


variable "db_name" {
  type = string
  default = "myappdb"
}

variable "lambda_runtime" {
  type = string
  default = "python3.12
}

variable "lamdba_timeout_seconds" {
  type = number
  default = 10
}

resource "lambda_memory_db" {
  type = number
  default = 256
}