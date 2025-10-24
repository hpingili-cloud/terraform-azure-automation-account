provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "bccd3288-f192-484e-8ca2-41459f718907" # WorkSafeBC Sandbox
}

run "setup" {
  module {
    source = "../.tests/setup"
  }
}

run "automation_account" {
  command = apply

  variables {
    name                = "tf-${run.setup.id}-aa"
    resource_group_name = run.setup.resource_group_name
    location            = run.setup.location

    credentials = [
      {
        name     = "test"
        username = "test"
        password = "test"
      }
    ]

    schedules = [
      {
        name       = "Last day each month"
        frequency  = "Month"
        month_days = [-1]
      }
    ]

    runbooks = [
      {
        name                     = "Confirm-TerraformTest"
        type                     = "PowerShell"
        content                  = "Write-Host \"Hello World\""
        runtime_environment_name = "test"
        schedule = {
          name = "Last day each month"
          parameters = {
            hello = "world"
          }
        }
      }
    ]

    runtime_environments = [
      {
        name = "test"
        runtime = {
          language = "PowerShell"
          version  = "7.4"
        }
        packages = {
          Az = "12.3.0"
        }
      }
    ]
  }

  assert {
    condition     = azurerm_automation_account.this.name == "tf-${run.setup.id}-aa"
    error_message = "Azure Automation Account did not match expected name tf-${run.setup.id}-aa"
  }

  assert {
    condition     = azurerm_automation_credential.this["test"].name == "test"
    error_message = "Azure Automation Account credential did not match expected name test"
  }

  assert {
    condition     = azurerm_automation_schedule.this["Last day each month"].name == "Last day each month"
    error_message = "Azure Automation Account credential did not match expected name `Last day each month`"
  }

  assert {
    condition     = azurerm_automation_runbook.this["Confirm-TerraformTest"].name == "Confirm-TerraformTest"
    error_message = "Azure Automation Account runbook did not match expected name `Confirm-TerraformTest`"
  }

  assert {
    condition     = azurerm_automation_job_schedule.this["Confirm-TerraformTest"].runbook_name == "Confirm-TerraformTest"
    error_message = "Azure Automation Account runbook schedule was not linked to `Confirm-TerraformTest`"
  }

  assert {
    condition     = azapi_resource.runtime_environments["test"].name == "test"
    error_message = "Azure Automation Account runtime environment did not match expected name test"
  }
}

