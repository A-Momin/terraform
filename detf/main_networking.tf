resource "aws_vpc" "detf_vpc" {
  cidr_block           = var.VPC_CIDR
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Project = var.project
    Name    = "${var.project}-vpc"
  }
}

##-------------------------------------------------------
##  CREATE SUBNETS FROM MAP OBJECTS
##-------------------------------------------------------

resource "aws_subnet" "public_subnets" {
  for_each                = var.PUBLIC_SUBNETS
  vpc_id                  = aws_vpc.detf_vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true # Enable Auto-assign Public IP; Default: false

  tags = {
    Project = "${var.project}"
    Name    = "${each.key}-${var.project}"
  }
}

resource "aws_subnet" "private_subnets" {
  for_each          = var.PRIVATE_SUBNETS
  vpc_id            = aws_vpc.detf_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Project = "${var.project}"
    Name    = "${each.key}-${var.project}"
  }
}

##-------------------------------------------------------
##  CREATE GATWAYS
##-------------------------------------------------------

resource "aws_internet_gateway" "detf_vpc_igw1" {
  vpc_id = aws_vpc.detf_vpc.id
  tags = {
    Project = "${var.project}"
    Name    = "${var.project}-igw"
  }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  #   vpc = true
  tags = {
    Project = "${var.project}"
    Name    = "${var.project}-eip"
  }
}
resource "aws_nat_gateway" "detf_vpc_ngw1" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id # NAT in Public Subnet
  tags = {
    Project = var.project
    Name    = "${var.project}-nat"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.detf_vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  route_table_ids   = [aws_route_table.detf_vpc_rt_public.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    Project = var.project
    Name    = "${var.project}-vpc-endpoint-s3"
  }
}

##-------------------------------------------------------
##  CREATE ROUTE TABLES
##-------------------------------------------------------

resource "aws_route_table" "detf_vpc_rt_public" {
  vpc_id = aws_vpc.detf_vpc.id
  tags = {
    Project = var.project
    Name    = "${var.project}-rtb-public"
  }
}
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.detf_vpc_rt_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.detf_vpc_igw1.id
}
resource "aws_route_table_association" "public_rtbl_association" {
  for_each       = toset(keys(aws_subnet.public_subnets))
  route_table_id = aws_route_table.detf_vpc_rt_public.id
  subnet_id      = aws_subnet.public_subnets[each.key].id
}


resource "aws_route_table" "detf_vpc_rt_private" {
  vpc_id = aws_vpc.detf_vpc.id
  tags = {
    Project = var.project
    Name    = "${var.project}-rtb-private"
  }

  #   # Route to NAT Gateway
  #   route {
  #     cidr_block = "0.0.0.0/0"
  #     gateway_id = aws_nat_gateway.detf_vpc_ngw1.id
  #   }
}
resource "aws_route" "internet_access_for_private_rtbl" {
  route_table_id         = aws_route_table.detf_vpc_rt_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.detf_vpc_ngw1.id
}
resource "aws_route_table_association" "private_rtbl_association" {
  for_each       = toset(keys(aws_subnet.private_subnets))
  route_table_id = aws_route_table.detf_vpc_rt_private.id
  subnet_id      = aws_subnet.private_subnets[each.key].id
}
