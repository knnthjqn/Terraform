resource "aws_vpc" "main" {
  Name = "${var.project_name}-${var.environment}-aws-vpc"
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-${var.environment}-aws-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    "${var.project_name}-${var.environment}-aws-igw"
  }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id = aws_vpc.main.id
  cidr_block = each.value.id
  availability_zones = each.key == "a" ? local.azs[0] : local.azs[1]
  map_public_ip_on_launch = true

  tags = {
    "${var.project_name}-${var.environment}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.main.id
  cidr_block = each.value.id
  availability_zones = each.key == "a" ? local.azs[0] : local.azs[1]

  tags = {
    "${var.project_name}-${var.environment}-private-subnet"
  }
}

resource "aws_subnet" "data" {
  for_each = local.data_subnets

  vpc_id = aws_vpc.main.id
  cidr_block = each.value.id
  availability_zones = each.key == "a" ? local.azs[0] : local.azs[1]

  tags = {
    Name = "${var.project_name}-${var.environment}-data-subnet"
  }
}

resource "aws_eip" "nat" {
  for_each = aws_subnet.public

  domain = "vpc" 

  tags = {
    "${var.project_name}-${var.environment}-eip"
  }
}

resource "nat_gateway" "main" {
  for_each = aws_subnet.public

  allocation_id = aws_eip.nat[each.key].id
  subnet_id = each.value.id

  depends_on = [aws_internet_gateway.main]

  tags = {

  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-route-table"
  }
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "nat_gateway.main[each.key].id"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-route-table"
  }
}

resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-data-route-table"
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  route_table_id = aws_route_table.public.id
  subnet_id = each.value.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  route_table_id = aws_route_table.private.id
  subnet_id = each.value.id
}

resource "aws_route_table_association" "data" {
  for_each = aws_subnet.data

  route_table_id = aws_route_table.data.id
  subnet_id = each.value.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat (
    [for rt in aws_route_table.private : rt.id],
    [aws_route_table.data.id]
  )

  tags = {
    Name = "${var.project_name}-${var.environment}-s3-endpoint"
  }
}