resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr
    enable_dns_hostname = true
    enable_dns_support = true

    tags = {
        name = name = "${var.project_name}-${var.environment}-vpc"
    }
}

resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id

    tags = {
        name = name = "${var.project_name}-${var.environment}-igw"
    }
}

resource "aws_subnet" "public" {
    for_each = local.public_subnets

    vpc_id = aws_vpc.main.id
    cidr_block = each.value
    availability_zones = each.key == "a" ? local.azs[0] : local.azs[1]
    map_public_ip_on_launch = true

    tags = {
        name = "${var.project_name}/public/${each.key}"
        tier = "Public"
    }
}

resource "aws_subnet" "private" {
    for_each = local.private_subnets

    vpc_id = aws_vpc.main.id
    cidr_block = each.value
    availability_zones = each.key == "a" ? local.azs[0] : local.azs[1]

    tags = {
        name = "${var.project_name}/private/${each.key}"
    }
}

resource "aws_eip" "nat" {
    for_each = aws_subnet.public
    domain = "vpc"
    
    tags = {
        name = "${var.project_name}/eip/${each.key}"
    }
}

resource "aws_nat_gateway" "main" {
    for_each = aww_subnet.public

    allocation_id = aws_eip.nat[each.key].id
    subnet_id = each.value.id

    depends_on = [aws_internet_gateway.main]

    tags = {
        name = name = "${var.project_name}/nat/${each.key}"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        name = name = "${var.project_name}-public-rt"
    }
}

resource "aws_route_table" "private" {
    for_each = aws_subnet.private  
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0"
        nat_gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        name = name = "${var.project_name}-private-rt"
    }
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

resource "aws_vpc_endpoint" "s3" {
    vpc_id = aws_vpc.main.id
    service_name = "com.amazonaws.${var.aws_region}.s3"
    vpc_endpoint_type = "Gateway"
    route_table_id = "for rt in aws_route_table.private : rt.id"

    tags = {
        name = "${var.project_name}-s3-endpoint"
    }
}
