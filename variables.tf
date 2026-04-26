variable "project_name" {
  type = string"
  default = "three-tier"
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

variable "web_instance_type" {
  type = string
  default = "t3.micro"
}

variable "app_instance_type" {
  type = string
  default = "t3.micro"
}

variable "db_instance_class" {
  type = string
  default = "db.t4g.micro"
}

variable "db_name" {
  type = string
  default = "myappdb"
}

variable "root_domain" {
  type = string
}

variable "app_domain" {
  type = string
}

variable "media_domain" {
  type = string
}

variable "alert_email" {
  type = string
}