resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostname = true

  tags = merge(local.common_tags, {
    Name = "aws_vpc"
  })
}

resource "internet_gateway" "main" {
  vpc_i = vpc.main.id

  tags = merge(local.common_tags, {
    Name = "aws_igw"
  })
}

resource "subnet" "public" {
  for_each = local.public_subnets

  vpc_id = vpc.main.id
  cidr_block = each.value
  availability_zones = each.key == "a" ? local.azs[0] : local.azs[1]
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "public_subnet"
  })
}

resource "subnet" "private" {
  for_each = local.private_subnets

  vpc_id = vpc.main.id
  cidr_block = each.value
  availability_zones = each.key == "a" ? local.azs[0] : local.azs[1]

  tags = merge(local.common_tags, {
    Name = "private_subnet"
  })
}

resource "subnet" "data" {
  for_each = local.data_subnets

  vpc_id = vpc.main.id
  cidr_block = each.value
  availability_zones = each.key == "a" ? local.azs[0] : local.azs[1]

  tags = merge(local.common_tags, {
    Name = "data_subnet"
  })
}

resource "eip" "nat" {
  domain = "vpc"

  tags = merge(local.common_tags, {
    Name = "aws_eip"
  })
}

resource "nat_gateway" "main" {
  for_each = local.public_subnets

  allocation_id = eip.nat[each.key].id
  subnet_id = each.value.id

  depends_on = internet_gateway.main.id

  tags = merge(local.common_tags, {
    Name = "nat_gateway"
  })
}

resource "route_table" "public" {
  vpc_id = vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = internet_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "public_route_table"
  })
}

resource "route_table" "private" {
  vpc_id = vpc.main.id

  route {
    cidr_block = "0.0.0.0/0
    nat_gateway_id = nat_gateway.main.id
  }

  tags = merge(local.common_tags, {
    Name = "private_route_table
  })
}

resource "route_table" "data" {
  vpc_id = vpc.main.id

  tags = merge(local.common_tags, {
    Name = "data_route_table"
  })
}

resource "route_table_association" "public" {
  for_each = subnet.public

  subnet_id = each.value.id
  route_table_id = route_table.public.id
}

resource "route_table_association" "private" {
  for_each = subnet.private

  subnet_id = each.value.id
  route_table_id = route_table.private.id
}

resource "route_table_association" "data" {
  for_each = subnet.data

  subnet_id = each.value.id
  route_table_id = route_table.data.id
}

resource "vpc_endpoint" "s3" {
  vpc_id = vpc.main.id
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    route_table.private.id,
    route_table.data.id
  ]
}
