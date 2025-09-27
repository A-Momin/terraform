
# # ------------------------
# # VPC + Subnets + IGW + Routes
# # ------------------------
# resource "aws_vpc" "asg_alb_vpc" {
#   cidr_block           = "172.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true
#   tags                 = { Name = "asg-alb-vpc" }
# }

# resource "aws_subnet" "public" {
#   count                   = 2
#   vpc_id                  = aws_vpc.asg_alb_vpc.id
#   cidr_block              = element(["172.0.1.0/24", "172.0.2.0/24"], count.index)
#   availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
#   map_public_ip_on_launch = true
#   tags                    = { Name = "asg-alb-public-${count.index}" }
# }

# resource "aws_subnet" "private" {
#   count             = 2
#   vpc_id            = aws_vpc.asg_alb_vpc.id
#   cidr_block        = element(["172.0.3.0/24", "172.0.4.0/24"], count.index)
#   availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
#   tags              = { Name = "asg-alb-private-${count.index}" }
# }

# resource "aws_internet_gateway" "this" {
#   vpc_id = aws_vpc.asg_alb_vpc.id
# }

# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.asg_alb_vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.this.id
#   }
# }

# resource "aws_route_table_association" "public" {
#   count          = 2
#   subnet_id      = aws_subnet.public[count.index].id
#   route_table_id = aws_route_table.public.id
# }
