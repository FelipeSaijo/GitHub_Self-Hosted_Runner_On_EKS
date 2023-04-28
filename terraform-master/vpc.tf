resource "aws_vpc" "main" {
    cidr_block           = "10.132.0.0/16"
    instance_tenancy     = "default"
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags = {
        Name = "FS_VPC_Runner"
    }
}

################################
#                              #
#     Public Subnet Config     #
#                              #
################################

resource "aws_subnet" "public_subnet" {
    vpc_id                  = aws_vpc.main.id
    count                   = length(var.public_subnets_cidrs)
    cidr_block              = element(var.public_subnets_cidrs, count.index)
    availability_zone       = element(var.availability_zones, count.index)
    map_public_ip_on_launch = true

    tags = {
      Name = "FS_Public_Subnet_${count.index + 1}"
    }
}

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.main.id    
    
    tags = {
      Name = "FS_IG_Runner"
    }
}

resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main.id    
    
    tags = {
      Name = "FS_Public_Route_Table"
    }
}

resource "aws_route" "public_route" {
    route_table_id         = aws_route_table.public_rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = aws_internet_gateway.internet_gateway.id
    depends_on             = [aws_route_table.public_rt]
}

resource "aws_route_table_association" "public_rt_association" {
    count = length(var.public_subnets_cidrs)
    subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
    route_table_id = aws_route_table.public_rt.id
}

################################
#                              #
#    Private Subnet Config     #
#                              #
################################

resource "aws_subnet" "private_subnet" {
    vpc_id                  = aws_vpc.main.id
    count                   = length(var.private_subnets_cidrs)
    cidr_block              = element(var.private_subnets_cidrs, count.index)
    availability_zone       = element(var.availability_zones, count.index)
    map_public_ip_on_launch = false

    tags = {
      Name = "FS_Private_Subnet_${count.index + 1}"
    }
}

resource "aws_eip" "nat_eip" {
  vpc        = true 
  depends_on = [aws_internet_gateway.internet_gateway]
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = "${aws_eip.nat_eip.id}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, 0)}"
  depends_on    = [aws_internet_gateway.internet_gateway]
  tags = {
    Name        = "FS_NATG_Runner"
  }
}

resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main.id    
    
    tags = {
      Name = "FS_Private_Route_Table"
    }
}

resource "aws_route" "private_route" {
    route_table_id         = aws_route_table.private_rt.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id         = aws_nat_gateway.nat_gateway.id
    depends_on             = [aws_route_table.private_rt]
}

resource "aws_route_table_association" "private_rt_association" {
    count = length(var.private_subnets_cidrs)
    subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
    route_table_id = aws_route_table.private_rt.id
}

################################
#                              #
#    Security Group Config     #
#                              #
################################

resource "aws_security_group" "allow_http" {
    name        = "allow_http"
    description = "Allow HTTP inbound traffic"
    vpc_id      = aws_vpc.main.id   
    
    ingress {
      description      = "HTTP from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }   
    
    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }   
    
    tags = {
      Name = "allow_http"
    }
}

resource "aws_security_group" "allow_https" {
    name        = "allow_https"
    description = "Allow HTTPS inbound traffic"
    vpc_id      = aws_vpc.main.id   
    
    ingress {
      description      = "HTTPS from VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }   
    
    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }   
    
    tags = {
      Name = "allow_https"
    }
}

resource "aws_security_group" "allow_ssh" {
    name        = "allow_ssh"
    description = "Allow SSH inbound traffic"
    vpc_id      = aws_vpc.main.id   
    
    ingress {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }   
    
    egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }   
    
    tags = {
      Name = "allow_ssh"
    }
}