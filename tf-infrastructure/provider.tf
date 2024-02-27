terraform {
 required_providers {
  #  aws = {
  #    source  = "hashicorp/aws"
  #  }
  #  tls = { 
  #   source = "hashicorp/tls"
  #  }
  #   random = {
  #     source  = "hashicorp/random"
  #   }
 }
}

provider "aws" { 
  region = "us-east-1" # Set your desired AWS region here
}

provider "tls" { 

}

provider "random" { 

}