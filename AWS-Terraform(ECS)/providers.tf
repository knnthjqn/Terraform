provider "aws" {
    region = var.region

    default_tags {
        tags = local.common_tags
    }
}

provider "aws" {
    region = "us-east-1"

    default_tags {
        tags = local.common_tags
    }
}