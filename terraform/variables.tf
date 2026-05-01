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
  description = "Your public IP in CIDR notation (e.g. 203.0.113.42/32). Only this IP can SSH into the instance."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_cidr)) && !endswith(var.allowed_ssh_cidr, "/0")
    error_message = "allowed_ssh_cidr must be a valid CIDR and must not be open to the world (e.g. use YOUR_IP/32)."
  }
}
