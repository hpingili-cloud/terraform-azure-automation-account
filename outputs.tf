output "id" {
  description = "The Azure resource id for the automation account."
  value       = azurerm_automation_account.this.id
}

output "name" {
  description = "The name of the automation account"
  value       = azurerm_automation_account.this.name
}

output "identities" {
  description = <<-EOT
    A list of managed identities for the Automation Account.

    - `identity_ids:` list(string)
      `principal_id:` string
      `tenant_id:`: string
      `type:` string

  EOT
  value       = azurerm_automation_account.this.identity
}
