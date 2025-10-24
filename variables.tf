variable "name" {
  type        = string
  description = "(Required) Specifies the name of the Automation Account. Changing this forces a new resource to be created."

  validation {
    error_message = "WorkSafeBC automation account names should end with `-aa`."
    condition     = var.enforce_naming_standard ? endswith(var.name, "-aa") : true
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{6,50}$", var.name))
    error_message = "The name must be between 6 and 50 characters long and can only contain letters, numbers and dashes."
  }

  validation {
    error_message = "The name must start with a letter"
    condition     = can(regex("^[a-zA-Z]", var.name))
  }

  validation {
    error_message = "The name cannot end with a dash."
    condition     = !endswith(var.name, "-")
  }
}

variable "resource_group_name" {
  type        = string
  description = "(Required) The name of the resource group in which the Automation Account is created. Changing this forces a new resource to be created."
}

variable "location" {
  type        = string
  default     = "canadacentral"
  description = "(Optional) The Azure location where the resources will be deployed. Default is `canadacentral`."
}

variable "sku_name" {
  type        = string
  default     = "Basic"
  description = "(Optional) The SKU of the account. Possible values are Basic and Free."
}

variable "local_authentication_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Whether requests using non-AAD authentication are blocked. Defaults to true."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = false
  description = "(Optional) Whether public network access is allowed for the automation account. Defaults to false."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) Map of tags to assign to the Key Vault resource."
}

variable "enforce_naming_standard" {
  type        = bool
  default     = true
  description = "(Optional) Enforces naming validation rules. If false, name validation rules are skipped."
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(list(string))
  })
  default     = null
  description = <<-EOT
    (Optional) `identity` block for Azure App Service.

    - `type` - (Required) Type of Managed Service Identity: SystemAssigned, UserAssigned, or both (SystemAssigned, UserAssigned).
    - `identity_ids` - (Optional) List of User Assigned Identity IDs.
    EOT
}


variable "credentials" {
  type = list(object({
    name        = string
    username    = string
    password    = string
    description = optional(string)
  }))
  default     = []
  sensitive   = true
  description = <<-EOT
    (Optional) A list of credentials to add to the automation account.

    - `name` - (Required) The name of the credential.
    - `username` - (Required) The username.
    - `password` - (Required) The password.
    - `description` - (Optional) A description for the credential.
    EOT
}

variable "schedules" {
  type = list(object({
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
  default     = []
  description = <<-EOT
    (Optional) A list of schedules that should be created.

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
  EOT

  validation {
    condition = alltrue([
      for schedule in var.schedules : contains(["OneTime", "Day", "Hour", "Week", "Month"], schedule.frequency)
    ])
    error_message = "'schedule.type' must be one of `OneTime`, `Day`, `Hour`, `Week`, or `Month`."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : (
        schedule.frequency == "Week"
        ? alltrue([for day in schedule.week_days : contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], schedule.week_days)])
        : true
      )
    ])
    error_message = "'schedule.week_days' must be one of `Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday` when frequence is `Week`."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : (
        schedule.frequency == "Month"
        ? alltrue([for day in schedule.month_days : day >= -1 && day <= 31])
        : true
      )
    ])
    error_message = "'schedule.month_days' must be between -1 and 31 when frequence is `Month`."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : (
        schedule.frequency == "Month" && schedule.monthly_occurrence != null
        ? contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], schedule.monthly_occurrence.day)
        : true
      )
    ])
    error_message = "'schedule.monthly_occurrence.day' must be one of `Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday` when setting monthly_occurence."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : (
        schedule.frequency == "Month" && schedule.monthly_occurrence != null && schedule.monthly_occurrence.day != null
        ? contains(["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"], schedule.monthly_occurrence.day)
        : true
      )
    ])
    error_message = "'schedule.monthly_occurrence.day' must be one of `Monday`, `Tuesday`, `Wednesday`, `Thursday`, `Friday`, `Saturday`, `Sunday` when setting monthly_occurence."
  }

  validation {
    condition = alltrue([
      for schedule in var.schedules : (
        schedule.frequency == "Month" && schedule.monthly_occurrence != null && schedule.monthly_occurrence.week != null
        ? schedule.monthly_occurrence.week >= -1 && schedule.monthly_occurrence.week <= 5
        : true
      )
    ])
    error_message = "'schedule.monthly_occurrence.week' must be between -1 and 5 when setting monthly_occurence."
  }
}

variable "runbooks" {
  type = list(object({
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
  default     = []
  description = <<-EOT
    (Optional) A list of runbooks to add to the Automation Account

    - `name` - (Required) Specifies the name of the Runbook. Changing this forces a new resource to be created.
    - `type` - (Required) The type of the runbook - can be either Graph, GraphPowerShell, GraphPowerShellWorkflow, PowerShellWorkflow, PowerShell, PowerShell72, Python3, Python2 or Script. Changing this forces a new resource to be created.
    - `content` - (Required) The desired content of the runbook.
    - `log_progress` - (Optional) Enable progress logging. Defaults to `true`.
    - `log_verbose` - (Optional) Enable verbose logging. Defaults to `false`.
    - `description` - (Optional) A description for the runbook.
    - `schedule` - (Optional) Run the runbook according to a schedule
        - `name` - (Required) The schedule name (from var.schedules).
        - `parameters` - (Optional) Any additional parameters to set when the runbook is scheduled

  EOT

  validation {
    condition = alltrue([
      for runbook in var.runbooks : contains(["Graph", "GraphPowerShell", "GraphPowerShellWorkflow", "PowerShellWorkflow", "PowerShell", "PowerShell72", "Python3", "Python2", "Script"], runbook.type)
    ])
    error_message = "'runbook.type' must be one of `Graph`, `GraphPowerShell`, `GraphPowerShellWorkflow`, `PowerShellWorkflow`, `PowerShell`, `PowerShell72`, `Python3`, `Python2`, or `Script`."
  }

  validation {
    condition = alltrue([
      for runbook in var.runbooks : alltrue([
        for param in keys(runbook.schedule.parameters) : param == lower(param)
      ]) if try(runbook.schedule.parameters, null) != null
    ])
    error_message = "The parameter names in 'runbook.schedule.parameters' must all be lowercase due to a bug in the SDK. See https://github.com/Azure/azure-sdk-for-go/issues/4780 for details. "
  }
}


variable "runtime_environments" {
  type = list(object({
    name = string
    runtime = object({
      language = string
      version  = string
    })
    description = optional(string)
    packages    = optional(map(string))
  }))
  default     = []
  description = <<-EOT
    (Optional) A list of runtime environments to include on the automation account. https://learn.microsoft.com/en-us/azure/automation/manage-runtime-environment

    - `name` - (Required) - The name of the runtime environment to create
    - `runtime` (Required) - A runtime object
        - `language` - (Required) - The runtime language to use
        - `version` - (Required) - The runtime version to use
    - `description` - (Optional) - A description of the runtime environment
    - `packages` - (Optional) - A map of additional packages and their versions to include. This can be nuget packages from the PowerShell Gallery.

  EOT
}
