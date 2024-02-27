terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
     version = "4.19.0"
   }
   tls = { 
    source = "hashicorp/tls"
    version = "4.0.5"
   }
    random = {
      source  = "hashicorp/random"
      version = "3.0"
    }
 }
 required_version = ""
}


provider "tls" {
  # Configuration options
}