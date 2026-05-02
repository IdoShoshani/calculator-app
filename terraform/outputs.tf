output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.calculator.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.calculator.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.calculator.public_dns
}

output "app_url" {
  description = "URL to reach the calculator API"
  value       = "http://${aws_instance.calculator.public_dns}:${var.app_port}"
}
