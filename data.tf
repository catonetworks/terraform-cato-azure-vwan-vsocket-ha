data "cato_accountSnapshotSite" "azure-site" {
  for_each = var.regional_config

  id = cato_socket_site.azure-site[each.key].id
}

data "cato_accountSnapshotSite" "azure-site-secondary" {
  for_each = var.regional_config

  depends_on = [null_resource.sleep_30_seconds]
  id         = cato_socket_site.azure-site[each.key].id
}

data "cato_accountSnapshotSite" "azure-site-2" {
  for_each = var.regional_config

  id         = cato_socket_site.azure-site[each.key].id
  depends_on = [null_resource.sleep_before_delete]
}

# Use a data source to get a reference to an existing Resource Group if not creating one.
data "azurerm_resource_group" "existing_rg" {
  count = !var.create_resource_group ? 1 : 0

  name = var.existing_resource_group_name
}

data "azurerm_virtual_network" "custom-vnet" {
  for_each = {
    for k, v in var.regional_config : k => v if v.vnet_name != null
  }

  name                = each.value.vnet_name
  resource_group_name = local.rg_name
}

# Combined VNET data source for VWAN integration
# This provides a unified interface for both created and existing VNETs
data "azurerm_virtual_network" "cato_vnet" {
  for_each = var.regional_config

  name                = each.value.vnet_name != null ? each.value.vnet_name : replace(replace("${var.prefix}-${each.key}-vsNet", "-", "_"), " ", "_")
  resource_group_name = local.rg_name

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# Use a data source to get a reference to an existing vWAN if not creating one.
data "azurerm_virtual_wan" "existing_vwan" {
  count = !var.create_vwan ? 1 : 0

  name                = var.existing_vwan_name
  resource_group_name = local.rg_name
}
