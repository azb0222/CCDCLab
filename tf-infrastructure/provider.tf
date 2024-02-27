terraform {
 required_providers {
   aws = {
     source  = "hashicorp/aws"
   }
   tls = { 
    source = "hashicorp/tls"
   }
    random = {
      source  = "hashicorp/random"
    }
 }
}
