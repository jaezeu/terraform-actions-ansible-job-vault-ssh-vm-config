# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------

variable "region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "aap"

  validation {
    condition     = can(regex("^[a-z0-9-]{1,20}$", var.name))
    error_message = "name must be 1-20 characters of lowercase letters, digits, or hyphens."
  }
}

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to reach the AAP web UI and API on 443. Keep this as narrow as possible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to SSH to the instance. Set to an empty list to disable SSH ingress and rely on SSM Session Manager."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type. The AAP containerized growth topology requires at least 4 vCPU and 16 GiB RAM."
  type        = string
  default     = "m6i.xlarge"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB. Red Hat recommends 60 GiB minimum, more if Automation Hub will store many collections and execution environments."
  type        = number
  default     = 120

  validation {
    condition     = var.root_volume_size >= 60
    error_message = "root_volume_size must be at least 60 GiB."
  }
}

variable "rhel_ami_name_filter" {
  description = "Name filter for the Red Hat published RHEL AMI. AAP 2.5+ containerized requires RHEL 9.2 or later."
  type        = string
  default     = "RHEL-9.6*_HVM-*-x86_64-*-Hourly2-GP3"
}

variable "ssh_public_key" {
  description = "Optional existing SSH public key for the instance key pair. When empty a new key pair is generated and the private key is written to ssh-key/."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# AAP installer
# ---------------------------------------------------------------------------

variable "aap_admin_password" {
  description = "Admin password for the platform gateway, controller, hub, and EDA. When empty a random password is generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "postgresql_admin_password" {
  description = "Password for the PostgreSQL admin user created by the installer. When empty a random password is generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "registry_username" {
  description = "registry.redhat.io username or service account used by the installer to pull AAP container images"
  type        = string
}

variable "registry_password" {
  description = "registry.redhat.io password or token"
  type        = string
  sensitive   = true
}

variable "install_automation_hub" {
  description = "Whether to include Automation Hub in the installer inventory"
  type        = bool
  default     = true
}

variable "install_eda" {
  description = "Whether to include Event-Driven Ansible in the installer inventory"
  type        = bool
  default     = true
}
