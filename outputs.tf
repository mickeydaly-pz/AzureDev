output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_windows_virtual_machine.main.public_ip_address
}

output "admin_password" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.main.admin_password
}

output "dsrm_password" {
  sensitive = true
  value     = random_password.password_dsrm.result
}

output "admin_password2" {
  sensitive = true
  value     = azurerm_windows_virtual_machine.backup.admin_password
}

output "dsrm_password2" {
  sensitive = true
  value     = random_password.password_dsrm2.result
}