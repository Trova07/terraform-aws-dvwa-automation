locals {
  public_subnet_ids  = [for subnet in aws_subnet.publics : subnet.id]
  private_subnet_ids = [for subnet in aws_subnet.privates : subnet.id]

  route_privates = var.number_of_nat_gws > 0 ? [
    for i in range(var.number_of_private_subnets) :
    [aws_nat_gateway.nat-gws[i % var.number_of_nat_gws].id]
  ] : []
}


resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = {
    Name = "${var.region_name}-vpc"
  }
}

resource "aws_subnet" "publics" {
  depends_on = [aws_vpc.main]
  count      = var.number_of_public_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.az_list[count.index % var.number_of_azs]
  cidr_block              = cidrsubnet(var.cidr_block, var.subnet_bits, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.region_name}-public-subnet-${count.index + 1}"
  }
}

resource "aws_subnet" "privates" {
  depends_on = [aws_vpc.main, aws_subnet.publics]
  count      = var.number_of_private_subnets

  vpc_id                  = aws_vpc.main.id
  availability_zone       = var.az_list[count.index % var.number_of_azs]
  cidr_block              = cidrsubnet(var.cidr_block, var.subnet_bits, count.index + pow(2, var.subnet_bits - 1))
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.region_name}-private-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.region_name}-igw"
  }
}

resource "aws_eip" "nat_eips" {
  count = var.number_of_nat_gws

  network_border_group = var.region
  tags = {
    Name = "${var.region_name}-nat-eip-${count.index + 1}"
  }
}

resource "aws_nat_gateway" "nat-gws" {
  count = var.number_of_nat_gws

  subnet_id     = local.public_subnet_ids[count.index % length(local.public_subnet_ids)]
  allocation_id = aws_eip.nat_eips[count.index].id
  tags = {
    Name = "${var.region_name}-nat-gw-${count.index + 1}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.region_name}-route-public"
  }
}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.privates)
  vpc_id = aws_vpc.main.id
  dynamic "route" {
    for_each = length(local.route_privates) > 0 ? local.route_privates[count.index] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = route.value
    }
  }
  tags = {
    Name = "${var.region_name}-route-private-${count.index + 1}"
  }
}

resource "aws_route_table_association" "publics" {
  count          = length(aws_subnet.publics)
  subnet_id      = aws_subnet.publics[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "privates" {
  count          = length(aws_subnet.privates)
  subnet_id      = aws_subnet.privates[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
