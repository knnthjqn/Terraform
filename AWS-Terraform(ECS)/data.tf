data "aws_availability_zones" "available" {
    status = "available"
}

data "aws-ami" "al2023" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "aws-ami"
        values = ["al2023-ami-2023*-x86_64"]
    }
}