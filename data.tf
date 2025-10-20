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

# --- NEW: Multi-Resource Group Data Sources ---

# vWAN Resource Group Data Source (for existing resource groups)
data "azurerm_resource_group" "vwan_existing" {
  count = (
    # New configuration takes precedence
    var.vwan_resource_group != null ?
    (!var.vwan_resource_group.create_new ? 1 : 0) :
    # Fall back to legacy configuration for backward compatibility
    !var.create_resource_group ? 1 : 0
  )

  name = local.vwan_rg_name
}

# vHub Resource Group Data Sources (for existing resource groups)
data "azurerm_resource_group" "vhub_existing" {
  for_each = {
    for region_key, region_config in var.regional_config :
    region_key => region_config
    if region_config.vhub_resource_group.strategy == "use_existing"
  }

  name = each.value.vhub_resource_group.name
}

# Cato Resource Group Data Sources (for existing resource groups)
data "azurerm_resource_group" "cato_existing" {
  for_each = {
    for region_key, region_config in var.regional_config :
    region_config.cato_resource_group.name => region_config
    # Only create data source if name is not null (not legacy fallback) and strategy is use_existing
    if region_config.cato_resource_group.name != null && region_config.cato_resource_group.strategy == "use_existing"
  }

  name = each.value.cato_resource_group.name
}

# --- DEPRECATED: Legacy Resource Group Data Source (for backward compatibility) ---
data "azurerm_resource_group" "existing_rg" {
  count = 0 # Disabled - functionality moved to vwan_existing

  name = var.existing_resource_group_name
}

data "azurerm_virtual_network" "custom-vnet" {
  for_each = {
    for k, v in var.regional_config : k => v if v.vnet_name != null
  }

  name                = each.value.vnet_name
  resource_group_name = local.cato_rg_names[each.key]
}

# Combined VNET data source for VWAN integration
# This provides a unified interface for both created and existing VNETs
data "azurerm_virtual_network" "cato_vnet" {
  for_each = var.regional_config

  name                = each.value.vnet_name != null ? each.value.vnet_name : replace(replace("${var.prefix}-${each.key}-vsNet", "-", "_"), " ", "_")
  resource_group_name = local.cato_rg_names[each.key]

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# Use a data source to get a reference to an existing vWAN if not creating one.
data "azurerm_virtual_wan" "existing_vwan" {
  count = !var.create_vwan ? 1 : 0

  name                = var.existing_vwan_name
  resource_group_name = local.vwan_rg_name
}
