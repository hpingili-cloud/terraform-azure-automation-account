module "automation_account" {
  source  = "app.terraform.io/wcbbc/automation_account/azurerm"
  version = "~> 0.0.2"

  resource_group_name           = module.resource_group.name
  tags                          = module.resource_group.tags
  location                      = var.automation_account.location
  name                          = var.automation_account.name
  sku_name                      = var.automation_account.sku_name
  public_network_access_enabled = true
  enforce_naming_standard       = false
  identity = {
    type         = var.automation_account.identity.type
    identity_ids = var.automation_account.identity.identity_ids
  }
}

automation_account = {
  name     = "DV-DV-CE--kdw-asr-automationaccount"
  sku_name = "Basic"
  location = "canadaeast"
  identity = {
    identity_ids = []
    type         = "SystemAssigned"
  }
}
