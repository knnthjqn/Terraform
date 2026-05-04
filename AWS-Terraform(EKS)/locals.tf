locals {
    azs = slice(data.aws_availabiltity_zones.available.names, 0, 2)

    common_tags = {
        Project = var.project_name
        Environment = var.environment
        Managedby = "Terraform"
    }

    public_subnets = {
        a = cidrsubnet(var.vpc_cidr, 8, 0)
        b = cidrsubnet(var.vpc_cidr, 8, 1)
    }

    private_subnets = {
        a = cidrsubnet(var.vpc_cidr, 8, 10)
        b = cidrsubnet(var.vpc_cidr, 8, 11)
    }

    app_namespace = "app"
    app_service_name = "app-service-name"
}