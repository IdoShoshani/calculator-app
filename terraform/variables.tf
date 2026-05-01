variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type (t2.micro is free-tier eligible)"
  type        = string
  default     = "t2.micro"
}

variable "app_port" {
  description = "Port the application listens on inside the container"
  type        = number
  default     = 8080
}

variable "ssh_key_name" {
  description = "Name of an existing EC2 key pair for SSH access"
  type        = string
}

variable "docker_image" {
  description = "Full Docker image reference to run on the instance (e.g. username/calculator-app:latest)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance. Restrict to your IP in production."
  type        = string
  default     = "0.0.0.0/0"
}
