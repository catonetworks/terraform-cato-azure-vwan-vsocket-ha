# Create HA user Assigned Identity
resource "azurerm_user_assigned_identity" "CatoHaIdentity" {
  for_each = var.regional_config

  location            = each.value.location
  name                = "${each.value.site_name}-CatoHaIdentity" ###Needing to be unique add ${sitename}-
  resource_group_name = local.rg_name
  tags                = merge(var.tags, { region = each.key })
}

resource "azurerm_role_assignment" "lan-subnet-role" {
  for_each = var.regional_config

  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity[each.key].principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = azurerm_subnet.subnet-lan[each.key].id
  depends_on           = [azurerm_user_assigned_identity.CatoHaIdentity, azurerm_subnet.subnet-lan]
}

resource "azurerm_role_assignment" "primary_nic_ha_role" {
  for_each = var.regional_config

  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity[each.key].principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = azurerm_network_interface.lan-nic-primary[each.key].id
  depends_on           = [azurerm_user_assigned_identity.CatoHaIdentity]
}

# Role assignments for secondary lan nic and subnet
resource "azurerm_role_assignment" "secondary_nic_ha_role" {
  for_each = var.regional_config

  principal_id         = azurerm_user_assigned_identity.CatoHaIdentity[each.key].principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = azurerm_network_interface.lan-nic-secondary[each.key].id
  depends_on           = [azurerm_linux_virtual_machine.vsocket_secondary]
  lifecycle {
    ignore_changes = [scope]
  }
}
