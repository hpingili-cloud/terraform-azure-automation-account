<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.9)

- <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) (~> 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 4.0)

## Providers

The following providers are used by this module:

- <a name="provider_azapi"></a> [azapi](#provider\_azapi) (~> 2.0)

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 4.0)

## Modules

No modules.

## Resources

The following resources are used by this module:

- [azapi_resource.runtime_environments](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource) (resource)
- [azapi_resource_action.remove_runtime_environments](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource_action) (resource)
- [azapi_update_resource.add_runtime_environments](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/update_resource) (resource)
- [azurerm_automation_account.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_account) (resource)
- [azurerm_automation_credential.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_credential) (resource)
- [azurerm_automation_job_schedule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_job_schedule) (resource)
- [azurerm_automation_runbook.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook) (resource)
- [azurerm_automation_schedule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_schedule) (resource)

## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: (Required) Specifies the name of the Automation Account. Changing this forces a new resource to be created.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: (Required) The name of the resource group in which the Automation Account is created. Changing this forces a new resource to be created.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_credentials"></a> [credentials](#input\_credentials)

Description: (Optional) A list of credentials to add to the automation account.

- `name` - (Required) The name of the credential.
- `username` - (Required) The username.
- `password` - (Required) The password.
- `description` - (Optional) A description for the credential.

Type:

```hcl
list(object({
    name        = string
    username    = string
    password    = string
    description = optional(string)
  }))
```

Default: `[]`

### <a name="input_enforce_naming_standard"></a> [enforce\_naming\_standard](#input\_enforce\_naming\_standard)

Description: (Optional) Enforces naming validation rules. If false, name validation rules are skipped.

Type: `bool`

Default: `true`

### <a name="input_identity"></a> [identity](#input\_identity)

Description: (Optional) `identity` block for Azure App Service.

- `type` - (Required) Type of Managed Service Identity: SystemAssigned, UserAssigned, or both (SystemAssigned, UserAssigned).
- `identity_ids` - (Optional) List of User Assigned Identity IDs.

Type:

```hcl
object({
    type         = string
    identity_ids = optional(list(string))
  })
```

Default: `null`

### <a name="input_local_authentication_enabled"></a> [local\_authentication\_enabled](#input\_local\_authentication\_enabled)

Description: (Optional) Whether requests using non-AAD authentication are blocked. Defaults to true.

Type: `bool`

Default: `true`

### <a name="input_location"></a> [location](#input\_location)

Description: (Optional) The Azure location where the resources will be deployed. Default is `canadacentral`.

Type: `string`

Default: `"canadacentral"`

### <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled)

Description: (Optional) Whether public network access is allowed for the automation account. Defaults to false.

Type: `bool`

Default: `false`

### <a name="input_runbooks"></a> [runbooks](#input\_runbooks)

Description: (Optional) A list of runbooks to add to the Automation Account

- `name` - (Required) Specifies the name of the Runbook. Changing this forces a new resource to be created.
- `type` - (Required) The type of the runbook - can be either Graph, GraphPowerShell, GraphPowerShellWorkflow, PowerShellWorkflow, PowerShell, PowerShell72, Python3, Python2 or Script. Changing this forces a new resource to be created.
- `content` - (Required) The desired content of the runbook.
- `log_progress` - (Optional) Enable progress logging. Defaults to `true`.
- `log_verbose` - (Optional) Enable verbose logging. Defaults to `false`.
- `description` - (Optional) A description for the runbook.
- `schedule` - (Optional) Run the runbook according to a schedule
    - `name` - (Required) The schedule name (from var.schedules).
    - `parameters` - (Optional) Any additional parameters to set when the runbook is scheduled

Type:

```hcl
list(object({
    name         = string
    type         = string
    content      = string
    log_progress = optional(bool, true)
    log_verbose  = optional(bool, false)
    description  = optional(string)
    schedule = optional(object({
      name       = string
      parameters = optional(map(string))
    }), null)
    runtime_environment_name = optional(string, null)
  }))
```

Default: `[]`

### <a name="input_runtime_environments"></a> [runtime\_environments](#input\_runtime\_environments)

Description: (Optional) A list of runtime environments to include on the automation account. https://learn.microsoft.com/en-us/azure/automation/manage-runtime-environment

- `name` - (Required) - The name of the runtime environment to create
- `runtime` (Required) - A runtime object
    - `language` - (Required) - The runtime language to use
    - `version` - (Required) - The runtime version to use
- `description` - (Optional) - A description of the runtime environment
- `packages` - (Optional) - A map of additional packages and their versions to include. This can be nuget packages from the PowerShell Gallery.

Type:

```hcl
list(object({
    name = string
    runtime = object({
      language = string
      version  = string
    })
    description = optional(string)
    packages    = optional(map(string))
  }))
```

Default: `[]`

### <a name="input_schedules"></a> [schedules](#input\_schedules)

Description: (Optional) A list of schedules that should be created.

- `name` (Required) - Specifies the name of the Schedule. Changing this forces a new resource to be created.
- `frequency` (Required) - The frequency of the schedule. - can be either `OneTime`, `Day`, `Hour`, `Week`, or `Month`.
- `interval` (Optional) - The number of frequencys between runs. Only valid when frequency is `Day`, `Hour`, `Week`, or `Month`.
- `timezone` (Optional) - The timezone of the start time. Defaults to `America/Vancouver`.
- `start_time` (Optional) - Start time of the schedule. Must be at least five minutes in the future. Defaults to seven minutes in the future from the time the resource is created.
- `expiry_time` (Optional) - The end time of the schedule.
- `description` (Optional) - A description for this Schedule.
- `week_days` (Optional) - List of days of the week that the job should execute on. Only valid when frequency is `Week`.
- `month_days` (Optional) - List of days of the month that the job should execute on. Must be between 1 and 31. -1 for last day of the month. Only valid when frequency is Month.
- `monthly_occurrence` (Optional) - List of occurrences of days within a month. Only valid when frequency is `Month`.
    - `day` (Optional) - Day of the occurrence. Must be one of `Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday`.
    - `week` (Optional) - Week of the occurence. Must be between 1 and 5. -1 for last week within the month.

Type:

```hcl
list(object({
    name        = string
    frequency   = string
    interval    = optional(number)
    timezone    = optional(string, "America/Vancouver")
    start_time  = optional(string)
    expiry_time = optional(string)
    description = optional(string)
    week_days   = optional(list(string))
    month_days  = optional(list(number))
    monthly_occurrence = optional(object({
      day        = optional(string, null)
      occurrence = optional(string, null)
    }), null)
  }))
```

Default: `[]`

### <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name)

Description: (Optional) The SKU of the account. Possible values are Basic and Free.

Type: `string`

Default: `"Basic"`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Map of tags to assign to the Key Vault resource.

Type: `map(string)`

Default: `{}`

## Outputs

The following outputs are exported:

### <a name="output_id"></a> [id](#output\_id)

Description: The Azure resource id for the automation account.

### <a name="output_identities"></a> [identities](#output\_identities)

Description: A list of managed identities for the Automation Account.

- `identity_ids:` list(string)
  `principal_id:` string
  `tenant_id:`: string
  `type:` string

### <a name="output_name"></a> [name](#output\_name)

Description: The name of the automation account
<!-- END_TF_DOCS -->