/* Subnet */
variable "subnets" {
  description = "A map of subnets to create"
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = bool
    name                    = string
  }))
  default = {
    #TODO only wireguard is map_public_ip_on_launch -> confim yes/no
    "wireguard" = {
      cidr_block              = "10.0.0.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = true
      name                    = "Wireguard"
    },
    "AD_corp_1" = {
      cidr_block              = "10.0.1.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = false
      name                    = "AD_corp"
    }
    "AD_corp_2" = {
      cidr_block              = "10.0.2.0/24"
      availability_zone       = "us-east-1b"
      map_public_ip_on_launch = false
      name                    = "AD_corp"
    }
    "ID_corp" = {
      cidr_block              = "10.0.3.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = false
      name                    = "ID_corp"
    }
    "K8" = {
      cidr_block              = "10.0.4.0/24"
      availability_zone       = "us-east-1a"
      map_public_ip_on_launch = false
      name                    = "K8"
    }
  }
}

# variable "private_subnets_route_tables_association" {
#   description = "A map of route tables assocations for private subnets"
#   type = map(object({
#     subnet_id = string
#   }))
#   default = {
#     "AD_corp_2" = {
#       subnet_id = aws_subnet.subnets["AD_corp_1"]
#     }
#     "AD_corp_2" = {
#       subnet_id = aws_subnet.subnets["AD_corp_2"]
#     }
#     "ID_corp" = {
#       subnet_id = aws_subnet.subnets["ID_corp"]
#     }
#     "K8" = {
#       subnet_id = aws_subnet.subnets["K8"]
#     }
#   }
# }
