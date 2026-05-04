variable "project_name" {
    type = string
    default = "test-architecture"
}

variable "environment" {
    type = string
    default = "dev"
}

variable "region" {
    type = string
    default = "ap-southeast-1"
}

variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16"
}

variable "eks_version" {
    type = string
    default = "1.32"
}

variable "alerts_email" {
    type = list(string)
    default = [
        "test@gmail.com",
        "try@gmail.com"
        ]
}

