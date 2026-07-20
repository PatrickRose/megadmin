# Migration plan: private (VNet) → public PostgreSQL

**Status:** proposal / runbook. Nothing here is applied yet.

## Why

The single biggest line on the Azure bill (~£16.45/mo, ~35% of the total) is the
**Standard Load Balancer + public IP** in the Container App Environment's managed
resource group (`me_cae-megadmin-production_...`), plus the private DNS zone.
Those exist **because the environment runs inside our own VNet**
(`infrastructure_subnet_id`), which is also what keeps PostgreSQL private.

Removing the custom VNet eliminates all of it:

| Removed | Monthly saving (GBP) |
|---|---:|
| Load Balancer (`capp-svc-lb`) | 13.41 |
| Static public IP (`capp-svc-lb-ip`) | 2.68 |
| Private DNS zone | 0.36 |
| **Total** | **~16.45** |

## The catch: two resources must be re-created

Both of these properties are **immutable** on Azure — they're fixed at creation,
so Terraform must destroy and re-create the resource:

1. **PostgreSQL Flexible Server** — the networking mode (Private/VNet vs Public)
   cannot be changed after creation. A public server is a **new** server; the
   data must be migrated.
2. **Container App Environment** — `infrastructure_subnet_id` (VNet integration)
   cannot be removed in place. A non-VNet environment is a **new** environment,
   which re-creates the web/worker/migrate apps and produces a **new ingress
   FQDN**.

## Impact / risks

- **Downtime** during the cutover window (DB + app). Fine for this low-traffic
  tool if scheduled between events.
- **New web FQDN** → the `megagameadmin.co.uk` CNAME must be repointed.
- **Weaker network isolation** — PostgreSQL becomes internet-reachable.
  Mitigations below. Note the firewall caveat: a **Consumption** Container Apps
  environment has **no stable outbound IP**, so you can't reliably firewall the
  DB to just the app. Realistic options:
  - **Allow public access from Azure services** (the special `0.0.0.0` firewall
    rule) — permits connections originating inside Azure, still gated by TLS +
    credentials. Broadest; simplest. This is the pragmatic default.
  - Restrict to specific IP ranges — only workable if you move to a
    **workload-profile** environment with a dedicated static outbound IP, which
    reintroduces cost and partly defeats the saving.
  - In all cases keep the existing hardening: `require_secure_transport = on`
    (already set), the 32-char auto-generated password, and a non-default admin
    username (already `megadmin_admin`).

**Honest recommendation:** the £16/mo is real money on a £46 bill, but this path
trades away network isolation and adds a data migration + DNS change. Worth doing
if the cost matters more than private networking for this app; otherwise the
scale-to-zero + ACR changes already trim ~30% with no security trade-off.

## Terraform changes required

**`postgres.tf`** — drop the VNet wiring, go public, add a firewall rule:

```hcl
resource "azurerm_postgresql_flexible_server" "main" {
  # ... unchanged: name, rg, location, version, admin, sku, storage, backups ...
  public_network_access_enabled = true      # was false
  # delegated_subnet_id         = ...        # REMOVED
  # private_dns_zone_id         = ...        # REMOVED
  # zone / depends_on on the DNS link        # REMOVED
}

# Allow connections from Azure-hosted services (Container Apps). Combined with
# require_secure_transport = on and the generated password.
resource "azurerm_postgresql_flexible_server_firewall_rule" "azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
```

**`container_apps.tf`** — remove VNet integration from the environment:

```hcl
resource "azurerm_container_app_environment" "main" {
  # ... unchanged ...
  # infrastructure_subnet_id = azurerm_subnet.container_apps.id   # REMOVED
}
```

`POSTGRES_HOST` stays `azurerm_postgresql_flexible_server.main.fqdn` — the `.fqdn`
attribute updates automatically to the new public hostname.

**`network.tf`** — delete the file (VNet, both subnets, private DNS zone, and the
VNet link are all no longer needed).

## Cutover runbook (maintenance-window / in-place)

> The Postgres resource keeps the same Terraform address, so `terraform apply`
> will **destroy the old server before creating the new one** — the data must be
> dumped first. The random password resource is unchanged, so the admin password
> (and its Key Vault secret) survives.

1. **Announce a maintenance window** and stop deploys.

2. **Back up the live DB while the VNet is still up.** The old server is only
   reachable from inside the VNet, so dump from a running container:
   ```bash
   az containerapp exec -n ca-megadmin-web -g rg-megadmin-production \
     --command "sh -c 'pg_dump \
       -h \$POSTGRES_HOST -U \$POSTGRES_USER -d \$POSTGRES_DB \
       --no-owner --no-privileges -Fc -f /tmp/megadmin.dump && \
       cat /tmp/megadmin.dump'" > megadmin.dump
   ```
   Verify the dump is non-empty and restorable (`pg_restore --list megadmin.dump`).
   Keep it safe — this is the rollback artifact.

3. **Apply the infrastructure change:**
   ```bash
   cd terraform
   terraform plan    # confirm: replace Postgres + environment, destroy VNet/subnets/DNS
   terraform apply
   ```
   This creates the new **public** server (empty), the new **non-VNet**
   environment (new FQDN), and tears down the VNet stack + LB + public IP.

4. **Restore the data into the new public server** (now reachable from your
   machine or CI over TLS):
   ```bash
   PGPASSWORD=$(az keyvault secret show --vault-name kv-megadmin-production \
     --name postgres-password --query value -o tsv)
   PGSSLMODE=require pg_restore --no-owner --no-privileges \
     -h psql-megadmin-production.postgres.database.azure.com \
     -U megadmin_admin -d megadmin_production megadmin.dump
   ```

5. **Run migrations & smoke-test** (belt and braces):
   ```bash
   az containerapp job start -n caj-megadmin-migrate -g rg-megadmin-production
   ```
   Then hit the new FQDN's `/up` and log in to confirm data is present.

6. **Repoint DNS.** Get the new FQDN and update the `megagameadmin.co.uk` CNAME:
   ```bash
   terraform output web_app_url
   ```
   Allow for TTL propagation.

7. **Confirm & close** the maintenance window; re-enable deploys.

## Rollback

If the new stack misbehaves before/after DNS cutover:

1. `git revert` the Terraform commit (restores private Postgres + VNet + DNS) and
   `terraform apply`.
2. Restore `megadmin.dump` into the recreated private server (step 2's method in
   reverse, from a container).
3. Point the CNAME back to the old FQDN.

Because the app is low-traffic, the small amount of data written between the dump
(step 2) and cutover is the only loss risk — schedule the window when the app is
idle to make that negligible.
