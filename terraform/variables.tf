variable "aws_region" {
  description = "Região AWS usada no provisionamento."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nome do projeto usado em nomes e tags dos recursos."
  type        = string
  default     = "devops-api-fase1"
}

variable "instance_type" {
  description = "Tipo da instância EC2. Ajuste de acordo com o laboratório AWS Academy disponível."
  type        = string
  default     = "t2.micro"
}

variable "application_port" {
  description = "Porta TCP usada pela API Node.js."
  type        = number
  default     = 3000
}

variable "repository_url" {
  description = "URL do repositório Git clonado na instância; contém o docker-compose.yml e os scripts de deploy."
  type        = string
  default     = "https://github.com/cbiazotto/devops-api-fase1.git"
}

variable "container_image" {
  description = "Imagem Docker da API, publicada pelo pipeline de CD no GitHub Container Registry, executada ao iniciar a instância."
  type        = string
  default     = "ghcr.io/cbiazotto/devops-api-fase1:latest"
}
