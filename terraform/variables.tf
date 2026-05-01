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

# Set one or both depending on your connection type.
# Find your IPs: curl -4 -s ifconfig.me (IPv4)  |  curl -6 -s ifconfig.me (IPv6)

variable "allowed_ssh_ipv4_cidr" {
  description = "Your public IPv4 in CIDR notation (e.g. 203.0.113.42/32). Null to skip."
  type        = string
  default     = null

  validation {
    condition     = var.allowed_ssh_ipv4_cidr == null || (can(cidrnetmask(var.allowed_ssh_ipv4_cidr)) && !endswith(var.allowed_ssh_ipv4_cidr, "/0"))
    error_message = "allowed_ssh_ipv4_cidr must be a valid IPv4 CIDR and must not be 0.0.0.0/0. Use YOUR_IP/32."
  }
}

variable "allowed_ssh_ipv6_cidr" {
  description = "Your public IPv6 in CIDR notation (e.g. 2001:db8::1/128). Null to skip."
  type        = string
  default     = null

  validation {
    condition     = var.allowed_ssh_ipv6_cidr == null || (!endswith(var.allowed_ssh_ipv6_cidr, "/0") && !endswith(var.allowed_ssh_ipv6_cidr, "::/0"))
    error_message = "allowed_ssh_ipv6_cidr must not be open to the world (::/0). Use YOUR_IPV6/128."
  }
}
