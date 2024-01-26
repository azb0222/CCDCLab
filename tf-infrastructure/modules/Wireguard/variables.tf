
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id-wireguard" {
  description = "Subnet ID"
  type        = string
}

variable "security_group-wireguard" {
  description = "Security Group ID"
  type        = string
}

variable "config_storage_bucket_id" { 
  description = "Config Storage Bucket ID"
  type        = string
}