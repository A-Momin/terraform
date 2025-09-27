resource "aws_vpc" "dev_glue_vpc" {
  cidr_block = "10.10.0.0/16"
  tags = {
    name = "dev-glue-vpc"
  }
}

resource "aws_internet_gateway" "dev_glue_vpc_igw1" {
  vpc_id = aws_vpc.dev_glue_vpc.id
  tags = {
    name = "dev-glue-igw"
  }
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.dev_glue_vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  route_table_ids   = [aws_route_table.dev_glue_vpc_rt1.id]
  vpc_endpoint_type = "Gateway"
  tags = {
    Environment = "dev"
    name        = "dev-glue-vpc-endpoint"
  }
}

resource "aws_route_table" "dev_glue_vpc_rt1" {
  vpc_id = aws_vpc.dev_glue_vpc.id
  tags = {
    Name = "dev-glue-rtb"
  }

  # Route to Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_glue_vpc_igw1.id
  }

  #   # Route to VPC Endpoint using Prefix List
  #   route {
  #     destination_prefix_list_id = aws_vpc_endpoint.s3_endpoint.prefix_list_id
  #     vpc_endpoint_id            = aws_vpc_endpoint.s3_endpoint.id
  #   }
}


# variable "dev_glue_subnets" {
#   type = list(object({
#     cidr_block        = string
#     availability_zone = string
#   }))

#   default = [
#     { cidr_block = "10.10.1.0/24", availability_zone = "us-east-1a" },
#     { cidr_block = "10.10.16.0/24", availability_zone = "us-east-1b" },
#     { cidr_block = "10.10.32.0/24", availability_zone = "us-east-1c" }
#   ]
# }

# resource "aws_subnet" "dev_glue_subnets" {
#   count             = length(var.dev_glue_subnets)
#   vpc_id            = aws_vpc.dev_glue_vpc.id
#   cidr_block        = var.dev_glue_subnets[count.index].cidr_block
#   availability_zone = var.dev_glue_subnets[count.index].availability_zone

#   tags = {
#     Name = "dev-glue-subnet-${count.index + 1}"
#   }
# }

# resource "aws_route_table_association" "rtbl_association" {
#   count          = length(aws_subnet.dev_glue_subnets)
#   route_table_id = aws_route_table.dev_glue_vpc_rt1.id
#   subnet_id      = aws_subnet.dev_glue_subnets[count.index].id
# }


##-------------------------------------------------------
##  CREATE SUBNETS FROM MAP OBJECTS
##-------------------------------------------------------
variable "dev_glue_subnets" {
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))

  default = {
    subnet_a = { cidr_block = "10.10.1.0/24", availability_zone = "us-east-1a" }
    subnet_b = { cidr_block = "10.10.16.0/24", availability_zone = "us-east-1b" }
    subnet_c = { cidr_block = "10.10.32.0/24", availability_zone = "us-east-1c" }
  }
}

resource "aws_subnet" "dev_glue_subnets" {
  for_each          = var.dev_glue_subnets
  vpc_id            = aws_vpc.dev_glue_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = "dev-glue-${each.key}"
  }
}


resource "aws_route_table_association" "rtbl_association" {
  for_each = toset(keys(aws_subnet.dev_glue_subnets))
  #   for_each       = tomap({ for k, v in aws_subnet.dev_glue_subnets : k => v.id })
  route_table_id = aws_route_table.dev_glue_vpc_rt1.id
  subnet_id      = aws_subnet.dev_glue_subnets[each.key].id
  #   subnet_id = each.value
}



# # (Optional) Explicit Route using Prefix List + VPC Endpoint target
# resource "aws_route" "s3_prefixlist_route" {
#   route_table_id             = aws_route_table.rtb.id
#   destination_prefix_list_id = aws_vpc_endpoint.s3_endpoint.prefix_list_id
#   vpc_endpoint_id            = aws_vpc_endpoint.s3_endpoint.id
# }

# resource "aws_security_group" "self_ref_sg" {
#   name        = "self-ref-sg"
#   description = "Allow all TCP traffic from within the same SG"
#   vpc_id      = aws_vpc.dev_glue_vpc.id

#   ingress {
#     description = "Allow all TCP from self"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     self        = true # 👈 Self-reference here
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "dev-glue-sg"
#   }
# }

# variable "custom_single_ports" {
#   description = "Custom ports to open on the security group"
#   type        = map(any)
#   default = {
#     80   = ["10.10.0.0/16"]
#     22   = ["10.10.0.0/16"]
#     8000 = ["10.10.0.0/16"]
#     5439 = ["10.10.0.0/16"]
#   }
# }

# resource "aws_security_group" "all_in_one_sg_a" {
#   vpc_id = aws_vpc.dev_glue_vpc.id
#   name   = "ALL-IN-ONE-SGS-SINGLE-PORT"
#   tags = {
#     Name = "dev-glue-sg"
#   }

#   dynamic "ingress" {
#     for_each = var.custom_single_ports
#     content {
#       from_port   = ingress.key
#       to_port     = ingress.key
#       protocol    = "tcp"
#       cidr_blocks = ingress.value
#     }
#   }
# }

# variable "custom_range_ports" {
#   type = map(object({
#     cidr_blocks = list(string)
#     from_port   = string
#     to_port     = string
#   }))

#   default = {
#     docker_host_communication = { cidr_blocks = ["10.10.0.0/16"], from_port = "32768", to_port = "60999" }
#   }
# }

# resource "aws_security_group" "all_in_one_sg_b" {
#   name   = "ALL-IN-ONE-SGS-RANGE-PORTS"
#   vpc_id = aws_vpc.dev_glue_vpc.id
#   tags = {
#     Name = "dev-glue-sg"
#   }

#   dynamic "ingress" {
#     for_each = var.custom_range_ports
#     content {
#       description = ingress.key
#       cidr_blocks = ingress.value.cidr_blocks
#       from_port   = ingress.value.from_port
#       to_port     = ingress.value.to_port
#       protocol    = "tcp"
#     }
#   }
# }


