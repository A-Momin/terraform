# resource "aws_vpc" "this" {
#   cidr_block           = var.vpc_cidr
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#   tags = {
#     Name = "${var.project}-vpc"
#   }
# }

# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.this.id
#   tags   = { Name = "${var.project}-igw" }
# }

# # Public subnet for NAT/management, but keep Redshift in private subnets
# resource "aws_subnet" "public" {
#   count                   = 1
#   vpc_id                  = aws_vpc.this.id
#   cidr_block              = cidrsubnet(var.vpc_cidr, 8, 0) # /24-ish
#   map_public_ip_on_launch = true
#   availability_zone       = var.azs[0]
#   tags                    = { Name = "${var.project}-public-subnet" }
# }

# # Two private subnets for Redshift across two AZs
# resource "aws_subnet" "private" {
#   count             = length(var.azs)
#   vpc_id            = aws_vpc.this.id
#   cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
#   availability_zone = var.azs[count.index]
#   tags = {
#     Name = "${var.project}-private-${count.index}"
#   }
# }

# # Route table for public subnet
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.this.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }
#   tags = { Name = "${var.project}-public-rt" }
# }

# resource "aws_route_table_association" "public_association" {
#   subnet_id      = aws_subnet.public[0].id
#   route_table_id = aws_route_table.public.id
# }

# # NAT Gateway for private subnets (simple demo - single NAT)
# resource "aws_eip" "nat_eip" {
#   domain = "vpc"
#   #   vpc = true
# }

# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat_eip.id
#   subnet_id     = aws_subnet.public[0].id
#   depends_on    = [aws_internet_gateway.igw]
#   tags          = { Name = "${var.project}-nat" }
# }

# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.this.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat.id
#   }
#   tags = { Name = "${var.project}-private-rt" }
# }

# resource "aws_route_table_association" "private_assocs" {
#   count          = length(aws_subnet.private)
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private.id
# }
