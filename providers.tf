provider "aws" {
    region = var.aws_region

    default_tags {
        tags = local.common_tags
    }
}

provider "aws" {
    region = "ap-southeast-1"

    default_tags {
        tags = {
            Project = var.project_name
            Environment = var.environment
            Managedby = "Terraform"
        }
    }
}