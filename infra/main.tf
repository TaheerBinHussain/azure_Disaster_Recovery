# ─────────────────────────────────────────────────────────────
# Terraform — Azure Free Tier Infrastructure
# Week 6: Cloud Native AI on Azure
# Subscription: e2ebe339-d55c-4da1-85f7-9a7e9c1d2f7a
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  subscription_id = var.subscription_id
}

# ── Data ──────────────────────────────────────────────────────
data "azurerm_client_config" "current" {}

# ── Variables ─────────────────────────────────────────────────
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "e2ebe339-d55c-4da1-85f7-9a7e9c1d2f7a"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
  default     = "week6-dr-rg"
}

variable "app_name" {
  description = "Container app name"
  type        = string
  default     = "week6-dr-app"
}

variable "image" {
  description = "Container image to deploy"
  type        = string
  default     = "ghcr.io/taheerbinhussain/azure_disaster_recovery:latest"
}

variable "app_version" {
  description = "App version tag"
  type        = string
  default     = "1.0.0"
}

# ── Resource Group ─────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    project = "week6-cloud-native-ai"
    week    = "6"
    cost    = "free-tier"
  }
}

# ── Log Analytics Workspace (FREE — 5 GB/month) ───────────────
resource "azurerm_log_analytics_workspace" "main" {
  name                = "week6-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30   # Minimum — keeps cost at $0

  tags = {
    cost = "free-tier"
  }
}

# ── Application Insights (FREE — 5 GB/month) ──────────────────
resource "azurerm_application_insights" "main" {
  name                = "week6-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = {
    cost = "free-tier"
  }
}

# ── Container App Environment (FREE) ──────────────────────────
resource "azurerm_container_app_environment" "main" {
  name                       = "week6-container-env"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  tags = {
    cost = "free-tier"
  }
}

# ── Container App (FREE — 180k vCPU-s/month) ─────────────────
resource "azurerm_container_app" "main" {
  name                         = var.app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name

  # Multiple = Blue/Green revision support
  revision_mode = "Multiple"

  identity {
    type = "SystemAssigned"
  }

  template {
    min_replicas = 0   # Scale to ZERO when idle = $0 cost
    max_replicas = 3   # Max 3 replicas — stays in free tier

    # HTTP scaling rule — scale out when traffic arrives
    http_scale_rule {
      name                = "http-scaling"
      concurrent_requests = 10
    }

    container {
      name   = "app"
      image  = var.image
      cpu    = 0.25    # Minimum CPU — free tier
      memory = "0.5Gi" # Minimum memory — free tier

      env {
        name  = "APP_VERSION"
        value = var.app_version
      }
      env {
        name  = "DEPLOYMENT_COLOR"
        value = "blue"
      }
      env {
        name  = "REGION"
        value = var.location
      }
      env {
        name  = "APPLICATIONINSIGHTS_CONNECTION_STRING"
        value = azurerm_application_insights.main.connection_string
      }

      # Liveness probe — self-healing: restart if unhealthy
      liveness_probe {
        path             = "/health"
        port             = 8000
        transport        = "HTTP"
        initial_delay    = 10
        period_seconds   = 30
        failure_count_threshold = 3
      }

      # Readiness probe — don't send traffic until app is ready
      readiness_probe {
        path      = "/ready"
        port      = 8000
        transport = "HTTP"
        period_seconds = 10
        failure_count_threshold = 3
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    transport        = "http"

    # 100% traffic to latest revision initially
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    cost = "free-tier"
  }
}

# ── Key Vault (FREE — 10k ops/month) ──────────────────────────
resource "azurerm_key_vault" "main" {
  name                        = "week6-kv-${substr(md5(var.subscription_id), 0, 6)}"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  # Allow Container App's managed identity to read secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_container_app.main.identity[0].principal_id

    secret_permissions = ["Get", "List"]
  }

  # Allow CI/CD service principal to write secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }

  tags = {
    cost = "free-tier"
  }
}

# ── Outputs ───────────────────────────────────────────────────
output "app_url" {
  description = "Public URL of the deployed application"
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "container_app_name" {
  description = "Container app name"
  value       = azurerm_container_app.main.name
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.main.name
}
