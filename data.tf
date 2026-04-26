data "aws_availability_zones" "available" {
    status = "available"
}

data "aws_ami" "al2023" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["al2023-ami-al2023*-x86_64"]
    }
}