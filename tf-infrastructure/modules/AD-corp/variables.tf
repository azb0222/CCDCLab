
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_id_cidr" {
  description = "VPC ID"
  type        = string
}


variable "subnet_id-AD-1" {
  description = "Subnet ID"
  type        = string
}

variable "subnet_id-AD-2" {
  description = "Subnet ID"
  type        = string
}


variable "security_group-wireguard" {
  description = "VPC ID"
  type        = string
}

variable "config_storage_bucket_id" { 
  description = "Config Storage Bucket ID"
  type        = string
}