locals {
    azs = slice(data.aws_availability_zones.available.names, 0, 2)

    common_tags = {
        Project = var.project_name
        Environment = var.environment
        Managedby = "Terraform"
    }

    public_subnets = {
        a = cidrsubnet(var.vpc_cidr, 8, 0)
        b = cidrsubnet(var.vpc_cidr, 8 ,1)
    }

    private_subnets = {
        a = cidrsubnet(var.vpc_cidr, 8, 10)
        b = cidrsubnet(var.vpc_cidr, 8, 11)
    }

    data_subnets = {
        a = cidrsubnet(var.vpc_cidr, 8, 20)
        b = cidrsubnet(var.vpc_cidr, 8, 21)
    }

    github_repository_full_name = "${var.github_owner}/${var.github_repo}"
}
