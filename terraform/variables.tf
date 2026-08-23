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
