/*
  AWS Provider
 */
provider "aws" {
  region = "us-east-1" # Set your desired AWS region here
}

/*
  1 VPC: 
  ccdc_setup_network: 10.0.0.0/16
*/
resource "aws_vpc" "ccdc_setup_network" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "ccdc-setup"
  }
}


/*
  4 SUBNETS: 
  Wireguard: 10.0.0.0/24
  AD_Corp: 10.0.1.0/24
  Id_Corp: 10.0.2.0/24
  K8: 10.0.3.0/24
*/


resource "aws_subnet" "subnets" {
  for_each                = var.subnets
  vpc_id                  = aws_vpc.ccdc_setup_network.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = {
    Name = each.value.name
  }
}


/*
  INTERNET CONNECTIVITY: 
  internet_gateway 
  NAT 
*/
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.ccdc_setup_network.id

  tags = {
    Name = "internet_gateway"
  }
}

resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "EIP for NAT Gateway"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnets["wireguard"].id

  tags = {
    Name = "gw NAT"
  }

  depends_on = [aws_internet_gateway.internet_gateway]
}

/*
  ROUTE TABLES
  Wireguard route table (public)
  AD_Corp route table (private)
  Id_Corp route table (private)
  K8 route table (private)
*/
resource "aws_route_table" "public_rt" { //allows traffic to flow from internet gateway to public wireguard subnet
  vpc_id = aws_vpc.ccdc_setup_network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "public_rt_a" {
  subnet_id      = aws_subnet.subnets["wireguard"].id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.ccdc_setup_network.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}
resource "aws_route_table_association" "private_route_table_associations" {
  for_each       = local.private_subnets_route_tables_association
  subnet_id      = each.value.subnet_id
  route_table_id = aws_route_table.private_route_table.id
}

/*
  SECURITY GROUPS 
  wg-bastion-security-group
  k8-security-group TODO 
*/
resource "aws_security_group" "wg-bastion-security-group" {
  name        = "wg-bastion-security-group"
  description = "Allow access from Internet through WireGuard and SSH"
  vpc_id      = aws_vpc.ccdc_setup_network.id

  ingress {
    description = "SSH from the Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Wireguard from the Internet"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web_traffic"
  }
}


# resource "aws_security_group" "workstation-security-group" {
#   name        = "workstation-security-group"
#   description = "Allow access from Wireguard Server only"
#   vpc_id      = aws_vpc.ccdc_setup_network.id

#   ingress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     security_groups = [aws_security_group.wg-bastion-security-group.id]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "allow_access_from_wireguard_only"
#   }
# }

