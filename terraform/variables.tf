variable "project_name" {
    type = string
    default = "test-stack-ec2"
}

variable "environment" {
    type = string
    default = "dev"
}

variable "aws_region" {
    type = string
    default = "ap-southeast-1"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "alerts_email" {
    type = list(string)
    default = ["test@gmail.com"]
}