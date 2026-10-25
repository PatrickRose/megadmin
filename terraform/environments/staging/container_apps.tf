locals {
  cae_default_domain = data.azurerm_container_app_environment.shared.default_domain

  # Deterministic FQDNs derived from the CAE domain (avoids self-reference).
  web_fqdn     = "ca-${var.project_name}-staging-web.${local.cae_default_domain}"
  mail_fqdn    = "ca-${var.project_name}-staging-mail.internal.${local.cae_default_domain}"
  app_hostname = var.app_hostname != "" ? var.app_hostname : local.web_fqdn

  image_placeholder = "${data.azurerm_container_registry.shared.login_server}/${var.project_name}:latest"

  # Staging runs the production Rails environment against isolated infra — driven
  # entirely by these env vars, so no dedicated staging.rb is needed.
  shared_env_vars = [
    { name = "RAILS_ENV", value = "production" },
    { name = "RAILS_LOG_TO_STDOUT", value = "1" },
    { name = "RAILS_SERVE_STATIC_FILES", value = "1" },
    { name = "POSTGRES_HOST", value = data.azurerm_postgresql_flexible_server.shared.fqdn },
    { name = "POSTGRES_USER", value = var.postgres_admin_username },
    { name = "POSTGRES_DB", value = azurerm_postgresql_flexible_server_database.staging.name },
    { name = "AZURE_STORAGE_ACCOUNT_NAME", value = data.azurerm_storage_account.shared.name },
    { name = "AZURE_STORAGE_CONTAINER", value = azurerm_storage_container.staging.name },
    { name = "APP_HOSTNAME", value = local.app_hostname },
    # Mail goes to the Mailpit catcher, never to Mailgun. No SMTP_USERNAME is set,
    # so config/application.rb sends with authentication: nil (see :62).
    { name = "SMTP_ADDRESS", value = local.mail_fqdn },
    { name = "SMTP_PORT", value = "1025" },
    { name = "MAILER_FROM", value = var.mailer_from },
    { name = "SENTRY_DSN", value = var.sentry_dsn },
  ]

  shared_secret_env_vars = [
    { name = "POSTGRES_PASSWORD", secret_name = "postgres-password" },
    { name = "SECRET_KEY_BASE", secret_name = "secret-key-base" },
    { name = "AZURE_STORAGE_ACCESS_KEY", secret_name = "storage-access-key" },
  ]

  # postgres-password and storage-access-key are reused from the shared Key Vault;
  # secret-key-base points at staging's own secret. All pulled with the shared
  # user-assigned identity (which already holds Key Vault Secrets User).
  shared_secrets = [
    { name = "postgres-password", key_vault_secret_id = data.azurerm_key_vault_secret.postgres_password.versionless_id, identity = data.azurerm_user_assigned_identity.shared.id },
    { name = "secret-key-base", key_vault_secret_id = azurerm_key_vault_secret.secret_key_base_staging.versionless_id, identity = data.azurerm_user_assigned_identity.shared.id },
    { name = "storage-access-key", key_vault_secret_id = data.azurerm_key_vault_secret.storage_access_key.versionless_id, identity = data.azurerm_user_assigned_identity.shared.id },
  ]
}

# Web
resource "azurerm_container_app" "web" {
  name                         = "ca-${var.project_name}-staging-web"
  container_app_environment_id = data.azurerm_container_app_environment.shared.id
  resource_group_name          = azurerm_resource_group.staging.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.shared.id]
  }

  registry {
    server   = data.azurerm_container_registry.shared.login_server
    identity = data.azurerm_user_assigned_identity.shared.id
  }

  dynamic "secret" {
    for_each = local.shared_secrets
    content {
      name                = secret.value.name
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 0
    max_replicas = 1

    container {
      name   = "web"
      image  = local.image_placeholder
      cpu    = var.web_cpu
      memory = var.web_memory

      dynamic "env" {
        for_each = local.shared_env_vars
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      dynamic "env" {
        for_each = local.shared_secret_env_vars
        content {
          name        = env.value.name
          secret_name = env.value.secret_name
        }
      }

      liveness_probe {
        transport = "HTTP"
        path      = "/up"
        port      = 3000
      }

      readiness_probe {
        transport = "HTTP"
        path      = "/up"
        port      = 3000
      }

      startup_probe {
        transport = "HTTP"
        path      = "/up"
        port      = 3000
      }
    }
  }

  tags = var.tags

  # The image is rolled by the deploy-staging workflow, not by Terraform.
  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}

# Worker
resource "azurerm_container_app" "worker" {
  name                         = "ca-${var.project_name}-staging-worker"
  container_app_environment_id = data.azurerm_container_app_environment.shared.id
  resource_group_name          = azurerm_resource_group.staging.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.shared.id]
  }

  registry {
    server   = data.azurerm_container_registry.shared.login_server
    identity = data.azurerm_user_assigned_identity.shared.id
  }

  dynamic "secret" {
    for_each = local.shared_secrets
    content {
      name                = secret.value.name
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name    = "worker"
      image   = local.image_placeholder
      cpu     = var.worker_cpu
      memory  = var.worker_memory
      command = ["bundle", "exec", "rake", "jobs:work"]

      dynamic "env" {
        for_each = local.shared_env_vars
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      dynamic "env" {
        for_each = local.shared_secret_env_vars
        content {
          name        = env.value.name
          secret_name = env.value.secret_name
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}

# Migration job — runs `db:migrate` against the staging database.
resource "azurerm_container_app_job" "migrate" {
  name                         = "caj-${var.project_name}-staging-migrate"
  container_app_environment_id = data.azurerm_container_app_environment.shared.id
  resource_group_name          = azurerm_resource_group.staging.name
  location                     = var.location
  replica_timeout_in_seconds   = 600
  replica_retry_limit          = 1

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.shared.id]
  }

  registry {
    server   = data.azurerm_container_registry.shared.login_server
    identity = data.azurerm_user_assigned_identity.shared.id
  }

  dynamic "secret" {
    for_each = local.shared_secrets
    content {
      name                = secret.value.name
      key_vault_secret_id = secret.value.key_vault_secret_id
      identity            = secret.value.identity
    }
  }

  manual_trigger_config {
    parallelism              = 1
    replica_completion_count = 1
  }

  template {
    container {
      name    = "migrate"
      image   = local.image_placeholder
      cpu     = 0.25
      memory  = "0.5Gi"
      command = ["bundle", "exec", "rake", "db:migrate"]

      dynamic "env" {
        for_each = local.shared_env_vars
        content {
          name  = env.value.name
          value = env.value.value
        }
      }

      dynamic "env" {
        for_each = local.shared_secret_env_vars
        content {
          name        = env.value.name
          secret_name = env.value.secret_name
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [template[0].container[0].image]
  }
}
