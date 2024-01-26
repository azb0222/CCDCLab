
resource "tls_private_key" "ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ssh_key_pair_ad" {
  key_name   = "ssh_key_pair_ad"
  public_key = tls_private_key.ssh_private_key.public_key_openssh
}

resource "aws_security_group" "AD_sg" {
  name        = "AD_VPC_Security_Group"
  description = "Security group for AD VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    security_groups =  [var.security_group-wireguard]
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
    Name = "AD_VPC_sg"
  }
}

resource "aws_iam_role" "EC2Domain_role" {
  name = "EC2Domain"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Role = "EC2Domain"
  }
}

// "This policy provides the minimum permissions necessary to use the Systems Manager service."
resource "aws_iam_role_policy_attachment" "SSMManagedInstanceCore" {
  role       = aws_iam_role.EC2Domain_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// "The policy provides the permissions to join instances to an Active Directory managed by AWS Directory Service."
resource "aws_iam_role_policy_attachment" "SSMDirectoryServiceAccess" {
  role       = aws_iam_role.EC2Domain_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMDirectoryServiceAccess"
}

resource "random_string" "random_hash" {
  length  = 16
  special = false
  upper   = false
  lower   = true
}


resource "aws_iam_instance_profile" "EC2Domain_profile" {
  name = "EC2Domain_profile_AD-${random_string.random_hash.result}"
  role = aws_iam_role.EC2Domain_role.name
}


  // The admin account credentials would be: 
  // username: umasscybersec\Admin
  // password: ihatedevops32!
resource "aws_directory_service_directory" "umasscybersec_ad" {
  name     = "umasscybersec.com"
  password = "ihatedevops32!"
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     =  var.vpc_id
    subnet_ids = [var.subnet_id-AD-1, var.subnet_id-AD-2]
  }

  tags = {
    Project = "umasscybersec_ad"
  }
}

data "aws_directory_service_directory" "my_domain_controller" { #TODO remove? 
  directory_id = aws_directory_service_directory.umasscybersec_ad.id 
}
resource "aws_ssm_document" "ad-join-domain" {
  name          = "ad-join-domain"
  document_type = "Command"
  content = jsonencode(
    {
      "schemaVersion" = "2.2"
      "description"   = "aws:domainJoin"
      "mainSteps" = [
        {
          "action" = "aws:domainJoin",
          "name"   = "domainJoin",
          "inputs" = {
            "directoryId" : data.aws_directory_service_directory.my_domain_controller.id,
            "directoryName" : data.aws_directory_service_directory.my_domain_controller.name
            "dnsIpAddresses" : sort(data.aws_directory_service_directory.my_domain_controller.dns_ip_addresses)
          }
        }
      ]
    }
  )
}
resource "aws_instance" "domain_controller" {
  ami           = "ami-035d8ae8de3734e5a"
  instance_type = "t3.micro"     
  subnet_id     = var.subnet_id-AD-1
  vpc_security_group_ids = [aws_security_group.AD_sg.id]
  key_name                    = aws_key_pair.ssh_key_pair_ad.key_name
  iam_instance_profile = aws_iam_instance_profile.EC2Domain_profile.name

  tags = {
    Name = "umasscybersec.com-mgmt"
  }
} 
resource "aws_ssm_association" "domain_controller_association" {
  name = aws_ssm_document.ad-join-domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.domain_controller.id]
  }
}

resource "aws_instance" "workstation_1" {
  ami           = "ami-035d8ae8de3734e5a"
  instance_type = "t3.micro"     
  subnet_id     = var.subnet_id-AD-1
  vpc_security_group_ids = [aws_security_group.AD_sg.id]
  key_name                    = aws_key_pair.ssh_key_pair_ad.key_name
  iam_instance_profile = aws_iam_instance_profile.EC2Domain_profile.name

  tags = {
    Name = "workstation_1"
  }
} 
resource "aws_ssm_association" "workstation_1_association" {
  name = aws_ssm_document.ad-join-domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.workstation_1.id]
  }
}

resource "aws_instance" "workstation_2" {
  ami           = "ami-035d8ae8de3734e5a"
  instance_type = "t3.micro"     
  subnet_id     = var.subnet_id-AD-1
  vpc_security_group_ids = [aws_security_group.AD_sg.id]
  key_name                    = aws_key_pair.ssh_key_pair_ad.key_name
  iam_instance_profile = aws_iam_instance_profile.EC2Domain_profile.name

  tags = {
    Name = "workstation_2"
  }
} 
resource "aws_ssm_association" "workstation_2_association" {
  name = aws_ssm_document.ad-join-domain.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.workstation_2.id]
  }
}
resource "local_file" "private_key_file" {
  content  = tls_private_key.ssh_private_key.private_key_pem
  filename = "${path.module}/ssh_keys/privatekey.pem"

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/ssh_keys && chmod 700 ${path.module}/ssh_keys"
  }
}

resource "aws_s3_object" "configuration-storage-bucket-ad-ssh" {
  bucket = var.config_storage_bucket_id
  key    = "ad-ssh-file.pem"
  source = local_file.private_key_file.filename
}
