
resource "tls_private_key" "ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ssh_key_pair" {
  key_name   = "ssh_key_pair"
  public_key = tls_private_key.ssh_private_key.public_key_openssh
}

resource "aws_instance" "wireguard_server" {
  ami                            = "ami-0c7217cdde317cfec"
  instance_type                  = "t2.medium"
  subnet_id                      = var.subnet_id-wireguard
  associate_public_ip_address    = true
  key_name                       = aws_key_pair.ssh_key_pair.key_name
  vpc_security_group_ids         = [var.security_group-wireguard]

  root_block_device {
    delete_on_termination = true
    volume_type           = "gp3"
    volume_size           = 15
  }

  tags = {
    Name = "Wireguard Server"
  }
}

resource "local_file" "private_key_file" {
  content  = tls_private_key.ssh_private_key.private_key_pem
  filename = "${path.module}/ssh_keys/privatekey.pem"
  
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/ssh_keys && chmod 700 ${path.module}/ssh_keys"
  }
}

resource "local_file" "tf_ansible_vpn_vars" {
  content = <<-DOC
    tf_vpn_server_ip: ${aws_instance.wireguard_server.public_ip}
    DOC

  filename =  "../ansible/playbooks/vpn/tf_ansible_vars.yml"
}

resource "local_file" "inventory" {
  content = <<-DOC
    [vpn]
    ${aws_instance.wireguard_server.public_ip}
    DOC

  filename = "../ansible/playbooks/vpn/inventory.ini"
}

resource "aws_s3_object" "configuration-storage-bucket-wireguard-server-ssh" {
  bucket = var.config_storage_bucket_id
  key    = "wireguard-server-ssh-file.pem"
  source = local_file.private_key_file.filename
}