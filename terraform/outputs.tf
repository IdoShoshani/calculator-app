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
  value       = "http://${aws_instance.calculator.public_ip}:${var.app_port}/api/calculate"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${local_sensitive_file.private_key.filename} ubuntu@${aws_instance.calculator.public_ip}"
}

output "private_key_path" {
  description = "Path to the generated private key file (use this as EC2_SSH_PRIVATE_KEY in GitHub Secrets)"
  value       = local_sensitive_file.private_key.filename
}
