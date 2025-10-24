resource "azurerm_role_assignment" "key_vault_secrets_user" {
  scope                = module.key_vault.id
  principal_id         = module.automation_account.identities[0].principal_id
  role_definition_name = "Key Vault Secrets User"
}

module "automation_account" {
  source  = "app.terraform.io/wcbbc/automation_account/azurerm"
  version = "~> 0.0.5"

  name                = "cc-mg-pr-cseauto-aa"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tags                = data.azurerm_resource_group.rg.tags
  runbooks            = local.runbooks

  identity = {
    type = "SystemAssigned"
  }

  runtime_environments = [
    {
      name = "wcbbc"
      runtime = {
        language = "PowerShell"
        version  = "7.4"
      }
      packages = {
        Az = "12.3.0"
        "Azure CLI" : "2.64.0"
      }
    }
  ]


  schedules = [
    {
      name       = "daily-1000pst"
      frequency  = "Day"
      interval   = 1
      start_time = "2025-09-10T10:00:00.0000000-07:00"
    }
  ]
}

resource "azurerm_role_assignment" "automation_operator" {
  scope                = module.automation_account.id
  principal_id         = module.automation_account.identities[0].principal_id
  role_definition_name = "Automation Operator"
}
