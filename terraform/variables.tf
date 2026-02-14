variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "megadmin"
}

variable "environment" {
  description = "Environment name (e.g. production, staging)"
  type        = string
  default     = "production"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    project     = "megadmin"
    environment = "production"
    managed_by  = "terraform"
  }
}

# Database
variable "postgres_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "megadmin_admin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
}

variable "postgres_database_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "megadmin_production"
}

variable "postgres_sku" {
  description = "PostgreSQL Flexible Server SKU"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "17"
}

# Rails
variable "rails_master_key" {
  description = "Rails master key for credentials decryption"
  type        = string
  sensitive   = true
}

variable "secret_key_base" {
  description = "Rails SECRET_KEY_BASE"
  type        = string
  sensitive   = true
}

variable "app_hostname" {
  description = "Application hostname for mailer and URL generation"
  type        = string
  default     = "megadmin.patrickrosemusic.co.uk"
}

# SMTP
variable "smtp_address" {
  description = "SMTP server address"
  type        = string
  default     = ""
}

variable "smtp_port" {
  description = "SMTP server port"
  type        = string
  default     = "587"
}

variable "smtp_username" {
  description = "SMTP username"
  type        = string
  default     = ""
}

variable "smtp_password" {
  description = "SMTP password"
  type        = string
  sensitive   = true
  default     = ""
}

# Container Apps
variable "web_min_replicas" {
  description = "Minimum number of web replicas"
  type        = number
  default     = 1
}

variable "web_max_replicas" {
  description = "Maximum number of web replicas"
  type        = number
  default     = 3
}

variable "web_cpu" {
  description = "CPU cores for web container"
  type        = number
  default     = 0.5
}

variable "web_memory" {
  description = "Memory (Gi) for web container"
  type        = string
  default     = "1Gi"
}

variable "worker_cpu" {
  description = "CPU cores for worker container"
  type        = number
  default     = 0.25
}

variable "worker_memory" {
  description = "Memory (Gi) for worker container"
  type        = string
  default     = "0.5Gi"
}

# GitHub OIDC
variable "github_repository" {
  description = "GitHub repository in format owner/repo"
  type        = string
  default     = "PatrickRose/megadmin"
}
