locals {
  tags = merge(var.tags, local.module_tags)
  module_tags = {
    tfc-module = "automation_account"
  }
}

resource "azurerm_automation_account" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku_name                      = var.sku_name
  local_authentication_enabled  = var.local_authentication_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = local.tags


  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }
}

resource "azurerm_automation_credential" "this" {
  for_each = { for credential in nonsensitive(var.credentials) : credential.name => credential }

  automation_account_name = azurerm_automation_account.this.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  name                    = each.value.name
  username                = each.value.username
  password                = each.value.password
  description             = each.value.description
}

resource "azurerm_automation_schedule" "this" {
  for_each = { for schedule in var.schedules : schedule.name => schedule }

  automation_account_name = azurerm_automation_account.this.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  name                    = each.value.name
  frequency               = each.value.frequency
  interval                = each.value.interval
  timezone                = each.value.timezone
  start_time              = each.value.start_time
  expiry_time             = each.value.expiry_time
  description             = each.value.description
  week_days               = each.value.week_days
  month_days              = each.value.month_days

  dynamic "monthly_occurrence" {
    for_each = each.value.monthly_occurrence != null ? [each.value.monthly_occurrence] : []

    content {
      day        = monthly_occurrence.value.day
      occurrence = monthly_occurrence.value.occurrence
    }
  }
}

resource "azurerm_automation_runbook" "this" {
  for_each = { for runbook in var.runbooks : runbook.name => runbook }

  automation_account_name = azurerm_automation_account.this.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  location                = azurerm_automation_account.this.location
  name                    = each.value.name
  runbook_type            = each.value.type
  content                 = each.value.content
  log_progress            = each.value.log_progress
  log_verbose             = each.value.log_verbose
  description             = each.value.description
  tags                    = local.tags
}

resource "azapi_update_resource" "add_runtime_environments" {
  for_each = { for runbook in var.runbooks : runbook.name => runbook if runbook.runtime_environment_name != null }

  type      = "Microsoft.Automation/automationAccounts/runbooks@2024-10-23"
  name      = azurerm_automation_runbook.this[each.value.name].name
  parent_id = azurerm_automation_account.this.id

  body = {
    properties = {
      runtimeEnvironment = azapi_resource.runtime_environments[each.value.runtime_environment_name].name
    }
  }
}


# Need to manually trigger the removal of the runtime environment
# on the runbook, otherwise terraform destroy will fail to delete the runbook
# because the environment is still attached
resource "azapi_resource_action" "remove_runtime_environments" {
  for_each = { for runbook in var.runbooks : runbook.name => runbook if runbook.runtime_environment_name != null }

  type        = "Microsoft.Automation/automationAccounts/runbooks@2024-10-23"
  resource_id = azurerm_automation_runbook.this[each.value.name].id

  when   = "destroy"
  method = "PATCH"
  body = {
    properties = {
      runtimeEnvironment = ""
    }
  }

  depends_on = [azapi_resource.runtime_environments]
}

resource "azurerm_automation_job_schedule" "this" {
  for_each = { for runbook in var.runbooks : runbook.name => runbook if try(runbook.schedule.name, null) != null }

  automation_account_name = azurerm_automation_account.this.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  schedule_name           = azurerm_automation_schedule.this[each.value.schedule.name].name
  runbook_name            = azurerm_automation_runbook.this[each.value.name].name
  parameters              = each.value.schedule.parameters
}

resource "azapi_resource" "runtime_environments" {
  for_each = { for environment in var.runtime_environments : environment.name => environment }

  type      = "Microsoft.Automation/automationAccounts/runtimeEnvironments@2024-10-23"
  name      = each.value.name
  parent_id = azurerm_automation_account.this.id
  body = {
    properties = {
      defaultPackages = each.value.packages
      description     = each.value.description
      runtime         = each.value.runtime
    }
  }
}
