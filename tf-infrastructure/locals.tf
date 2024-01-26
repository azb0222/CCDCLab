
locals {
  private_subnets_route_tables_association = {
    "AD_corp_1" = { subnet_id = aws_subnet.subnets["AD_corp_1"].id }
    "AD_corp_2" = { subnet_id = aws_subnet.subnets["AD_corp_2"].id }
    "ID_corp"   = { subnet_id = aws_subnet.subnets["ID_corp"].id }
    "K8"        = { subnet_id = aws_subnet.subnets["K8"].id }
  }
}
