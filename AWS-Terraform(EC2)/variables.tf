variable "project_name" {
    type = string
    default = "test-ec2-stack"
}

variable "environment" {
    type = string
    default = "prod"
}

variable "aws_region" {
    type = string
    default = "ap-southeast-1"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "db_name" {
    type = string
    default = "myappdb"
}

variable "db_instance_class" {
    type = string
    default = "db.t4g.micro"
}

variable "alerts_email" {
    type = string
}