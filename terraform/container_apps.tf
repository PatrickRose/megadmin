resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project_name}-${var.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  infrastructure_subnet_id   = azurerm_subnet.container_apps.id

  tags = var.tags
}

locals {
  shared_env_vars = [
    { name = "RAILS_ENV", value = "production" },
    { name = "RAILS_LOG_TO_STDOUT", value = "1" },
    { name = "RAILS_SERVE_STATIC_FILES", value = "1" },
    { name = "POSTGRES_HOST", value = azurerm_postgresql_flexible_server.main.fqdn },
    { name = "POSTGRES_USER", value = var.postgres_admin_username },
    { name = "POSTGRES_DB", value = var.postgres_database_name },
    { name = "AZURE_STORAGE_ACCOUNT_NAME", value = azurerm_storage_account.main.name },
    { name = "AZURE_STORAGE_CONTAINER", value = azurerm_storage_container.active_storage.name },
    { name = "APP_HOSTNAME", value = var.app_hostname },
    { name = "SMTP_ADDRESS", value = var.smtp_address },
    { name = "SMTP_PORT", value = var.smtp_port },
    { name = "SMTP_USERNAME", value = var.smtp_username },
  ]

  shared_secret_env_vars = [
    { name = "POSTGRES_PASSWORD", secret_name = "postgres-password" },
    { name = "SECRET_KEY_BASE", secret_name = "secret-key-base" },
    { name = "RAILS_MASTER_KEY", secret_name = "rails-master-key" },
    { name = "AZURE_STORAGE_ACCESS_KEY", secret_name = "storage-access-key" },
    { name = "SMTP_PASSWORD", secret_name = "smtp-password" },
  ]

  shared_secrets = [
    { name = "postgres-password", key_vault_secret_id = azurerm_key_vault_secret.postgres_password.versionless_id, identity = azurerm_user_assigned_identity.container_app.id },
    { name = "secret-key-base", key_vault_secret_id = azurerm_key_vault_secret.secret_key_base.versionless_id, identity = azurerm_user_assigned_identity.container_app.id },
    { name = "rails-master-key", key_vault_secret_id = azurerm_key_vault_secret.rails_master_key.versionless_id, identity = azurerm_user_assigned_identity.container_app.id },
    { name = "storage-access-key", key_vault_secret_id = azurerm_key_vault_secret.storage_access_key.versionless_id, identity = azurerm_user_assigned_identity.container_app.id },
    { name = "smtp-password", key_vault_secret_id = azurerm_key_vault_secret.smtp_password.versionless_id, identity = azurerm_user_assigned_identity.container_app.id },
  ]

  image_placeholder = "${azurerm_container_registry.main.login_server}/${var.project_name}:latest"
}

# Web Container App
resource "azurerm_container_app" "web" {
  name                         = "ca-${var.project_name}-web"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.container_app.id
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
    min_replicas = var.web_min_replicas
    max_replicas = var.web_max_replicas

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

  lifecycle {
    ignore_changes = [
      template[0].container[0].image,
    ]
  }
}

# Worker Container App
resource "azurerm_container_app" "worker" {
  name                         = "ca-${var.project_name}-worker"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.container_app.id
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
    ignore_changes = [
      template[0].container[0].image,
    ]
  }
}

# Migration Job
resource "azurerm_container_app_job" "migrate" {
  name                         = "caj-${var.project_name}-migrate"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  replica_timeout_in_seconds   = 600
  replica_retry_limit          = 1

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app.id]
  }

  registry {
    server   = azurerm_container_registry.main.login_server
    identity = azurerm_user_assigned_identity.container_app.id
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
    ignore_changes = [
      template[0].container[0].image,
    ]
  }
}
