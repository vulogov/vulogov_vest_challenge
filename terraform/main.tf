# Generate random ID for unique naming
resource "random_id" "suffix" {
  byte_length = 4
  
  keepers = {
    CandidateId = var.candidate_id
    Environment = var.environment
  }
}

# Generate SSH key pair
resource "tls_private_key" "ssh_key" {
  algorithm = var.ssh_key_algorithm
  rsa_bits  = var.ssh_key_bits
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = local.ssh_private_key_path
  file_permission = "0600"
  
  provisioner "local-exec" {
    command = "chmod 600 ${self.filename}"
  }
}

# Save public key locally
resource "local_file" "public_key" {
  content         = tls_private_key.ssh_key.public_key_openssh
  filename        = local.ssh_public_key_path
  file_permission = "0644"
}

# Create AWS key pair
resource "aws_key_pair" "demo_key" {
  key_name   = "${local.name_prefix}-${random_id.suffix.hex}"
  public_key = tls_private_key.ssh_key.public_key_openssh
  
  tags = merge(local.common_tags, {
    Name = "ssh-key-${local.name_prefix}"
  })
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = merge(local.common_tags, {
    Name = "vpc-${local.name_prefix}"
  })
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "igw-${local.name_prefix}"
  })
}

# Create public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index % length(local.azs)]
  map_public_ip_on_launch = true
  
  tags = merge(local.common_tags, {
    Name = "public-subnet-${count.index + 1}-${local.name_prefix}"
    Type = "public"
    AZ   = local.azs[count.index % length(local.azs)]
  })
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(local.common_tags, {
    Name = "public-rt-${local.name_prefix}"
  })
}

# Associate public subnets with route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)
  
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security group for EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg-${local.name_prefix}"
  description = "Security group for EC2 instances"
  vpc_id      = aws_vpc.main.id
  
  tags = merge(local.common_tags, {
    Name = "ec2-sg-${local.name_prefix}"
  })
}

# Security group rules
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ec2_sg.id
  
  cidr_ipv4   = var.allowed_ssh_cidr
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  
  description = "SSH access"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.ec2_sg.id
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  
  description = "HTTP access"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.ec2_sg.id
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  
  description = "HTTPS access"
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.ec2_sg.id
  
    cidr_ipv4   = "0.0.0.0/0"
    from_port   = 8080
    to_port     = 8080
    ip_protocol = "tcp"
	  
    description = "Application access"
}
	 

resource "aws_vpc_security_group_egress_rule" "all_traffic" {
  security_group_id = aws_security_group.ec2_sg.id
  
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"
  
  description = "Allow all outbound traffic"
}

# Create EC2 instances
resource "aws_instance" "demo_instances" {
  count = var.instance_count
  
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.demo_key.key_name
  
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  
  associate_public_ip_address = true
  
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    
    tags = merge(local.common_tags, {
      Name = "root-volume-${count.index + 1}-${local.name_prefix}"
    })
  }
  
   user_data = <<-EOT
    #!/bin/bash
    INSTANCE_NUMBER=${count.index + 1}
    CANDIDATE_ID="${var.candidate_id}"
    HOSTNAME="web-server-$${INSTANCE_NUMBER}"
    
    hostnamectl set-hostname "$HOSTNAME"
    yum update -y
    yum -y install rust rust-static rust-toolset cargo openssl-devel sqlite sqlite-devel
    yum -y install curl
    amazon-linux-extras install ansible2 -y
    yum -y install awscli
    /usr/sbin/ldconfog -v
  EOT
  
  tags = merge(local.common_tags, {
    Name         = "ec2-${count.index + 1}-${local.name_prefix}"
    InstanceRole = "web-app-server"
    AZ           = aws_subnet.public[count.index % length(aws_subnet.public)].availability_zone
  })
  
  lifecycle {
    ignore_changes = [
      ami,  # Ignore AMI updates to prevent recreation
      user_data
    ]
  }
}

# Create S3 bucket
resource "aws_s3_bucket" "demo_storage" {
  bucket = local.s3_bucket_full_name
  
  tags = merge(local.common_tags, {
    Name = "s3-${local.name_prefix}"
  })
}

# Enable bucket versioning
resource "aws_s3_bucket_versioning" "versioning" {
  count = var.enable_s3_versioning ? 1 : 0
  
  bucket = aws_s3_bucket.demo_storage.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  count = var.enable_s3_encryption ? 1 : 0
  
  bucket = aws_s3_bucket.demo_storage.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.demo_storage.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create bucket policy
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.demo_storage.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "SecureTransportPolicy"
    Statement = [
      {
        Sid       = "ForceSSL"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.demo_storage.arn,
          "${aws_s3_bucket.demo_storage.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
