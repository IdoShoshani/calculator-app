terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  # Credentials come from environment variables:
  # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
}

# ── Resolve the latest Ubuntu 22.04 LTS AMI dynamically ──────────────────────
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ── VPC & Networking ──────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block                       = "10.0.0.0/16"
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = { Name = "calculator-app-vpc", Project = "calculator-app" }
}

resource "aws_subnet" "public" {
  vpc_id                          = aws_vpc.main.id
  cidr_block                      = "10.0.1.0/24"
  ipv6_cidr_block                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = "${var.aws_region}a"

  tags = { Name = "calculator-app-public", Project = "calculator-app" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = { Name = "calculator-app-igw", Project = "calculator-app" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }

  tags = { Name = "calculator-app-rt", Project = "calculator-app" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Security Group ────────────────────────────────────────────────────────────
resource "aws_security_group" "calculator_sg" {
  name        = "calculator-app-sg"
  description = "Allow inbound traffic on app port and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Application traffic (IPv4 + IPv6)"
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  # SSH — IPv4 (only added when allowed_ssh_ipv4_cidr is set)
  dynamic "ingress" {
    for_each = var.allowed_ssh_ipv4_cidr != null ? [var.allowed_ssh_ipv4_cidr] : []
    content {
      description = "SSH access (IPv4)"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # SSH — IPv6 (only added when allowed_ssh_ipv6_cidr is set)
  dynamic "ingress" {
    for_each = var.allowed_ssh_ipv6_cidr != null ? [var.allowed_ssh_ipv6_cidr] : []
    content {
      description      = "SSH access (IPv6)"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      ipv6_cidr_blocks = [ingress.value]
    }
  }

  egress {
    description      = "Allow all outbound (needed to pull Docker images)"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "calculator-app-sg", Project = "calculator-app" }

  lifecycle {
    precondition {
      condition     = var.allowed_ssh_ipv4_cidr != null || var.allowed_ssh_ipv6_cidr != null
      error_message = "You must set at least one of allowed_ssh_ipv4_cidr or allowed_ssh_ipv6_cidr."
    }
  }
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────
resource "aws_instance" "calculator" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.calculator_sg.id]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    docker_image = var.docker_image
    app_port     = var.app_port
  })

  user_data_replace_on_change = true

  tags = { Name = "calculator-app", Project = "calculator-app" }
}
