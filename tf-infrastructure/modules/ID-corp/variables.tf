variable "subnet_id-ID-corp" {
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

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}