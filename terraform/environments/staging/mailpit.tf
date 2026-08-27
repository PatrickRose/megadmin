# Mailpit — a dead-end SMTP catcher so staging can NEVER deliver real email.
# The staging web/worker send to it on 1025; captured mail is viewed on the 8025 UI.
#
# Provisioned via azapi because a Container App needs TWO ports (SMTP 1025 + UI
# 8025) and azurerm's `ingress` models only a single port. `additionalPortMappings`
# exposes the second. Ingress is internal; view the UI with:
#   az containerapp ingress show / `az containerapp exec` port-forwarding, or set
#   external = true below plus MP_UI_AUTH + an IP allowlist for a bookmarkable URL.
#
# NOTE: exact ingress/port shape may need a small tweak on first apply — this is
# the one piece that can't be fully validated without deploying (see the change's
# tasks.md, task 2.1).
resource "azapi_resource" "mailpit" {
  type      = "Microsoft.App/containerApps@2024-03-01"
  name      = "ca-${var.project_name}-staging-mail"
  parent_id = azurerm_resource_group.staging.id
  location  = var.location

  body = {
    properties = {
      managedEnvironmentId = data.azurerm_container_app_environment.shared.id
      configuration = {
        ingress = {
          external   = false
          targetPort = 8025
          transport  = "http"
          additionalPortMappings = [
            {
              external    = false
              targetPort  = 1025
              exposedPort = 1025
            }
          ]
        }
      }
      template = {
        containers = [
          {
            name  = "mailpit"
            image = "axllent/mailpit:latest"
          }
        ]
        # Always-on (min 1) so it is ready to catch SMTP and the UI stays up.
        # Captured mail is in-memory and does not survive a restart — fine for staging.
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  }

  tags = var.tags
}
