

resource "tls_private_key" "ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ssh_key_pair_id-corp" {
  key_name   = "ssh_key_pair_id-corp"
  public_key = tls_private_key.ssh_private_key.public_key_openssh
}
resource "aws_instance" "Wazuh" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ssh_key_pair_id-corp.key_name
  vpc_security_group_ids      = [aws_security_group.ID_Corp_SG.id]
  subnet_id     = var.subnet_id-ID-corp
  tags = {
    Name = "Wazuh"
  }
}

resource "aws_instance" "AnsibleController" {
  ami                         = "ami-0c7217cdde317cfec"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.ssh_key_pair_id-corp.key_name
  vpc_security_group_ids      =  [aws_security_group.ID_Corp_SG.id]
  subnet_id     = var.subnet_id-ID-corp
  tags = {
    Name = "AnisbleController"
  }
}

resource "aws_security_group" "ID_Corp_SG" {
  name        = "ID_Corp_SG"
  description = "Security group for ID_Corp"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups =  [var.security_group-wireguard]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ID_Corp_SG"
  }
}


resource "local_file" "private_key_file" {
  content  = tls_private_key.ssh_private_key.private_key_pem
  filename = "${path.module}/ssh_keys/privatekey.pem"

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/ssh_keys && chmod 700 ${path.module}/ssh_keys"
  }
}

resource "aws_s3_object" "configuration-storage-bucket-id-corp-ssh" {
  bucket = var.config_storage_bucket_id
  key    = "id-corp-ssh.pem"
  source = local_file.private_key_file.filename
}
