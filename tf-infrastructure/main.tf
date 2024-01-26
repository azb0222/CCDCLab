//contains bucket to store Terraform state files 
terraform {
  backend "s3" {
    bucket = "ccdc2024-test-infra-state-file"
    key    = "my-terraform-project"
    region = "us-east-2"
  }
}


//Modules
module "Wireguard" { 
  source = "./modules/Wireguard"
  vpc_id              = aws_vpc.ccdc_setup_network.id
  subnet_id-wireguard = aws_subnet.subnets["wireguard"].id
  security_group-wireguard = aws_security_group.wg-bastion-security-group.id
  config_storage_bucket_id = aws_s3_bucket.configuration-storage-bucket.id
}
module "AD-corp" {
  source            = "./modules/AD-corp"
  vpc_id              = aws_vpc.ccdc_setup_network.id
  vpc_id_cidr = aws_vpc.ccdc_setup_network.cidr_block
  subnet_id-AD-1 = aws_subnet.subnets["AD_corp_1"].id
  subnet_id-AD-2 = aws_subnet.subnets["AD_corp_2"].id
  security_group-wireguard = aws_security_group.wg-bastion-security-group.id
  config_storage_bucket_id = aws_s3_bucket.configuration-storage-bucket.id
}

module "K8" {
  source              = "./modules/K8"
  vpc_id              = aws_vpc.ccdc_setup_network.id
  subnet_id-K8 = aws_subnet.subnets["K8"].id
  security_group-wireguard = aws_security_group.wg-bastion-security-group.id
  config_storage_bucket_id = aws_s3_bucket.configuration-storage-bucket.id
}

module "ID-corp" {
  source            = "./modules/ID-corp"
  vpc_id              = aws_vpc.ccdc_setup_network.id
  subnet_id-ID-corp = aws_subnet.subnets["ID_corp"].id
  security_group-wireguard = aws_security_group.wg-bastion-security-group.id
  config_storage_bucket_id = aws_s3_bucket.configuration-storage-bucket.id
}


