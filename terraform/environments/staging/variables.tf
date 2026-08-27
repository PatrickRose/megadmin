variable "subscription_id" {
  description = "Azure subscription ID (same subscription as production)"
  type        = string
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "megadmin"
}

variable "shared_environment" {
  description = "Environment name of the shared platform to reuse (its resources are looked up by name)"
  type        = string
  default     = "production"
}

variable "location" {
  description = "Azure region (must match the shared platform)"
  type        = string
  default     = "uksouth"
}

variable "postgres_admin_username" {
  description = "PostgreSQL administrator username on the shared server"
  type        = string
  default     = "megadmin_admin"
}

variable "app_hostname" {
  description = "Custom hostname for staging. Leave empty to use the auto-assigned Container Apps FQDN."
  type        = string
  default     = ""
}

variable "mailer_from" {
  description = "Default from address for mailers on staging"
  type        = string
  default     = "no-reply@staging.megagameadmin.co.uk"
}

variable "sentry_dsn" {
  description = "Sentry DSN for staging (leave empty to disable so staging noise stays out of production Sentry)"
  type        = string
  default     = ""
}

variable "github_repository" {
  description = "GitHub repository in owner/repo form (for the staging deploy OIDC federated credential)"
  type        = string
  default     = "PatrickRose/megadmin"
}

variable "web_cpu" {
  type    = number
  default = 0.25
}

variable "web_memory" {
  type    = string
  default = "0.5Gi"
}

variable "worker_cpu" {
  type    = number
  default = 0.25
}

variable "worker_memory" {
  type    = string
  default = "0.5Gi"
}

variable "tags" {
  description = "Tags applied to staging-specific resources"
  type        = map(string)
  default = {
    project     = "megadmin"
    environment = "staging"
    managed_by  = "terraform"
  }
}
