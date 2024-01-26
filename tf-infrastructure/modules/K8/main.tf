resource "tls_private_key" "ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ssh_key_pair_k8" {
  key_name   = "ssh_key_pair_k8"
  public_key = tls_private_key.ssh_private_key.public_key_openssh
}
//NOTE: I GOT RID OFF ALL THE PORTS THAT SHOULDA BEEN OPEN IDK IF THIS IS GONNA BREAK ANYTHING IN THE FUTURE 

// Security group for the master node
resource "aws_security_group" "k8Master_security_group" {
  name        = "k8MasterSecurityGroup"
  description = "Security group for master node"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups =  [var.security_group-wireguard]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Security group for worker nodes
resource "aws_security_group" "k8Worker_security_group" {
  name        = "k8WorkerSecurityGroup"
  vpc_id      = var.vpc_id
  description = "Security group for worker nodes"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups =  [var.security_group-wireguard]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
// IAM ROLE + POLICIES 
resource "aws_iam_role" "k8Master_role" {
  name = "k8Master_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}


//idk if i even need this bc the ebs_csi has the permissions anyway but im just keeping it for now 
resource "aws_iam_role_policy" "k8Master_policy" {
  name = "k8Master_policy"
  role = aws_iam_role.k8Master_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateVolume",
          "ec2:DeleteVolume"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
    ],
  })
}

resource "aws_iam_role" "k8Worker_role" {
  name = "k8Worker_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
      },
    ],
  })
}


resource "aws_iam_role_policy" "k8Worker_policy" {
  name = "k8Worker_policy"
  role = aws_iam_role.k8Worker_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups",
          "ec2:CreateVolume",
          "ec2:DeleteVolume"
          /*  
          TODO: technically it should only be 
                 "ec2:DescribeInstances",
          "ec2:AttachVolume",
          "ec2:DetachVolume",
          "ec2:DescribeVolumes",
          "ec2:DescribeSecurityGroups"
          i will fix later just wanna get it working 

          */
        ],
        Effect   = "Allow",
        Resource = "*"
      },
    ],
  })
}
resource "aws_iam_user" "ebs_csi_user" {
  name = "ebs-csi-driver-user"
  # additional optional parameters like path, permissions_boundary, etc.
}

resource "aws_iam_access_key" "ebs_csi_user_key" {
  user = aws_iam_user.ebs_csi_user.name
}

resource "aws_iam_user_policy_attachment" "ebs_csi_policy_attachment" {
  user       = aws_iam_user.ebs_csi_user.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "local_file" "aws_credentials" {
  content  = <<EOF
AWS Access Key ID: ${aws_iam_access_key.ebs_csi_user_key.id}
AWS Secret Access Key: ${aws_iam_access_key.ebs_csi_user_key.secret}
EOF
  filename = "${path.module}/aws_credentials.txt"
}

resource "random_string" "random_hash" {
  length  = 16
  special = false
  upper   = false
  lower   = true
}


// Master node instance
resource "aws_iam_instance_profile" "k8_master_profile" {
  name = "k8_master_profile-${random_string.random_hash.result}"
  role = aws_iam_role.k8Master_role.name
}

resource "aws_instance" "k8Master" {
  //PLEASE MAKE SURE TO USE UBUNTU 20.04 AND NOT UBUNTU 22.04. UBUNUTU 22.04 LEADS TO ALL SORTS OF FUCKING ISSUES
  ami                         = "ami-06aa3f7caf3a30282"
  instance_type               = "t2.xlarge"
  key_name                    = aws_key_pair.ssh_key_pair_k8.key_name
  vpc_security_group_ids      = [aws_security_group.k8Master_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.k8_master_profile.name
  subnet_id     = var.subnet_id-K8

  root_block_device {
    volume_size = 25 // Specify your desired volume size here in GB
  }

  tags = {
    Name = "k8Master"
  }
}
resource "aws_iam_instance_profile" "k8_worker_profile" {
  name = "k8_worker_profile_hash"
  role = aws_iam_role.k8Worker_role.name
}

// Worker node 1 instance
resource "aws_instance" "k8worker1" {
  //PLEASE MAKE SURE TO USE UBUNTU 20.04 AND NOT UBUNTU 22.04. UBUNUTU 22.04 LEADS TO ALL SORTS OF FUCKING ISSUES
  ami                         = "ami-06aa3f7caf3a30282"
  instance_type               = "t2.xlarge"
  key_name                    = aws_key_pair.ssh_key_pair_k8.key_name
  vpc_security_group_ids      = [aws_security_group.k8Worker_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.k8_worker_profile.name
  subnet_id     = var.subnet_id-K8

  root_block_device {
    volume_size = 25 // Specify your desired volume size here in GB
  }

  tags = {
    Name = "k8worker1"
  }
}

// Worker node 2 instance
resource "aws_instance" "k8worker2" {
  ami                         = "ami-06aa3f7caf3a30282"
  instance_type               = "t2.xlarge"
  key_name                    = aws_key_pair.ssh_key_pair_k8.key_name
  vpc_security_group_ids      = [aws_security_group.k8Worker_security_group.id]
  iam_instance_profile        = aws_iam_instance_profile.k8_worker_profile.name
  subnet_id     = var.subnet_id-K8

  root_block_device {
    volume_size = 25 // Specify your desired volume size here in GB
  }


  tags = {
    Name = "k8worker2"
  }
}


resource "local_file" "private_key_file" {
  content  = tls_private_key.ssh_private_key.private_key_pem
  filename = "${path.module}/ssh_keys/privatekey.pem"

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/ssh_keys && chmod 700 ${path.module}/ssh_keys"
  }
}

resource "aws_s3_object" "configuration-storage-bucket-k8-ssh" {
  bucket = var.config_storage_bucket_id
  key    = "k8-ssh.pem"
  source = local_file.private_key_file.filename
}
