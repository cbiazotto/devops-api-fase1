data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

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

resource "aws_security_group" "app" {
  name        = "${var.project_name}-sg"
  description = "Security Group da API academica"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Acesso HTTP a API"
    from_port   = var.application_port
    to_port     = var.application_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Saida para Internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg"
    Project     = var.project_name
    Environment = "academic"
    ManagedBy   = "Terraform"
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.app.id]

  # Bootstrap do servidor: clona o repositório, instala o Docker e sobe a API
  # em container a partir da imagem publicada pelo pipeline de CD.
  user_data = <<-EOF
    #!/bin/bash
    set -e
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y git curl
    git clone ${var.repository_url} /opt/devops-api
    chown -R ubuntu:ubuntu /opt/devops-api
    bash /opt/devops-api/deploy/install-docker.sh
    cd /opt/devops-api
    IMAGE=${var.container_image} PORT=${var.application_port} bash deploy/deploy.sh
  EOF

  tags = {
    Name        = "${var.project_name}-ec2"
    Project     = var.project_name
    Environment = "academic"
    ManagedBy   = "Terraform"
  }
}
