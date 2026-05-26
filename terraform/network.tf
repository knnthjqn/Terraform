resource "aws_vpc" "main" {
    cidr_block = "${var.vpc_cidr}
    enable_dns_hostname = true
    enable_dns_support = true
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
}

resource "aws_subnet" "public" {
    for_each = local.public_subnets

    vpc_id = aws_vpc.main.id
    cidr_block = each.value
    availability_zones = local.azs[index(keys(local.public_subnets), each.key)]
    map_public_ip_on_launch = true

    tags = {
        name = "${var.project_name}-public-subnets"
    }
}

resource "aws_subnet" "private" {
    for_each = local.private_subnets

    vpc_id = aws_vpc.main.id
    cidr_block = each.value
    availability_zones = local.azs[index(keys(local.private_subnets), each.key)]

    tags = {
        name = "${var.project_name}-private-subnets"
    }
}

resource "aws_subnet" "data" {
    for_each = local.data_subnets

    vpc_id = aws_vpc.main.id
    cidr_block = each.value
    availability_zones = local.azs[index(keys(local.data_subnets), each.key)]

    tags = {
        name = "${var.project_name}-data-subnets"
    }
}

resource "aws_eip" "nat" {
    for_each = aws_subnet.public

    domain = "vpc"
}

resource "aws_nat_gateway" "main" {
    for_each = aws_subnet.public

    subnet_id = each.value.id
    allocation_id = aws_eip.nat[each.key].id

    depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }
}

resource "aws_route_table" "private" {
    for_each = aws_subnet.private
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main[each.key].id
    }
}

resource "aws_route_table" "data" {
    vpc_id = aws_vpc.main.id
}

resource "aws_route_table_association" "public" {
    for_each = aws_subnet.public

    subnet_id = each.value.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
    for_each = aws_subnet.private 

    subnet_id = each.value.id
    route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "data" {
    for_each = aws_subnet.data

    subnet_id = each.value.id
    route_table_id = aws_route_table.data.id
}
