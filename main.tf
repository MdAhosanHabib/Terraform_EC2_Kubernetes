provider "aws" {
  region     = "us-east-1"
  access_key = "AKIAVJ5QC7DQY62ZP35Q"
  secret_key = "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"
}


// To Generate Private Key
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

variable "key_name" {
  description = "Name of the SSH key pair"
}
// Create Key Pair for Connecting EC2 via SSH
resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

// Save PEM file locally
resource "local_file" "private_key" {
  content  = tls_private_key.rsa_4096.private_key_pem
  filename = var.key_name
}


resource "aws_vpc" "ahosan_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "ahosan_igw" {
  vpc_id = aws_vpc.ahosan_vpc.id
}

resource "aws_subnet" "ahosan_subnet" {
  vpc_id     = aws_vpc.ahosan_vpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_route_table" "ahosan_route_table" {
  vpc_id = aws_vpc.ahosan_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ahosan_igw.id
  }
}

resource "aws_route_table_association" "ahosan_route_table_association" {
  subnet_id      = aws_subnet.ahosan_subnet.id
  route_table_id = aws_route_table.ahosan_route_table.id
}

resource "aws_security_group" "ahosan_sg_all_ports" {
  name        = "allow_all_ports"
  description = "Allow all ports bidirectionally within the group"
  vpc_id      = aws_vpc.ahosan_vpc.id

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    self           = true
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    self           = true
  }

  // Allow SSH (port 22) for inbound traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ahosan_sg_http" {
  name        = "allow_http"
  description = "Allow HTTP traffic for specific instances"
  vpc_id      = aws_vpc.ahosan_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ahosan_ec2" {
  count = 4

  ami           = "ami-079db87dc4c10ac91"  # Replace with AmazonLinux AMI ID
  instance_type = "t2.medium"
  key_name      = aws_key_pair.key_pair.key_name
  subnet_id     = aws_subnet.ahosan_subnet.id

  vpc_security_group_ids = concat(
    [aws_security_group.ahosan_sg_all_ports.id],
    count.index == 0 ? [aws_security_group.ahosan_sg_http.id] : []
  )

  associate_public_ip_address = true  # Explicitly assign public IPs for t2.medium

  tags = {
    Name = count.index == 0 ? "ahosan-ec2-nginx" : "ahosan-ec2-${count.index + 1}"
  }
}

#resource "aws_instance" "ahosan_ec2" {
#  count = 4
#
#  ami           = "ami-0c7217cdde317cfec"  # Replace with Ubuntu AMI ID
#  instance_type = "t2.medium"
#  subnet_id     = aws_subnet.ahosan_subnet.id
#
#  associate_public_ip_address = true
#
#  tags = {
#    Name = count.index == 0 ? "ahosan-ec2-nginx" : "ahosan-ec2-${count.index + 1}"
#  }
#
#  # Apply security groups based on instance index
#  dynamic "vpc_security_group_ids" {
#    for_each = count.index == 0 ? [1] : []
#    content {
#      vpc_security_group_id = aws_security_group.ahosan_sg_http.id
#    }
#  }
#
#  #Always apply the "allow_all_ports" security group
#  vpc_security_group_ids = concat(aws_security_group.ahosan_sg_all_ports.id, vpc_security_group_ids)
#}

output "instance_with_http_access_public_ip" {
  value = aws_instance.ahosan_ec2[0].public_ip
}

output "private_ips" {
  value = aws_instance.ahosan_ec2.*.private_ip
}

output "public_ips" {
  value = aws_instance.ahosan_ec2.*.public_ip
}

