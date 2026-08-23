output "instance_id" {
  description = "ID da instância EC2 provisionada."
  value       = aws_instance.app.id
}

output "public_ip" {
  description = "IP público da instância EC2."
  value       = aws_instance.app.public_ip
}

output "application_url" {
  description = "URL prevista para acesso à API após a aplicação ser implantada."
  value       = "http://${aws_instance.app.public_ip}:${var.application_port}"
}

output "security_group_id" {
  description = "ID do Security Group criado para a API."
  value       = aws_security_group.app.id
}
