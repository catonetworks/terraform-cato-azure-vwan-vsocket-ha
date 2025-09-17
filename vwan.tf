# -----------------------------------------------------------------
# VIRTUAL WAN (Conditional)
# -----------------------------------------------------------------
resource "azurerm_virtual_wan" "vwan" {
  count = var.create_vwan ? 1 : 0

  name                = "${var.prefix}-vwan"
  resource_group_name = local.rg_name
  location            = var.primary_location
  type                = "Standard"
  tags                = var.tags
}

# -----------------------------------------------------------------
# VIRTUAL HUBS (Conditional, Per-Hub)
# -----------------------------------------------------------------
resource "azurerm_virtual_hub" "vhub_new" {
  # Create a hub only for regions where create_hub is true.
  for_each = {
    for k, v in var.regional_config : k => v if v.create_hub
  }

  name                   = "${var.prefix}-vhub-${each.key}"
  resource_group_name    = local.rg_name
  location               = each.value.location
  virtual_wan_id         = local.vwan_id
  address_prefix         = each.value.hub_address_prefix
  sku                    = "Standard"
  hub_routing_preference = each.value.hub_routing_preference
  branch_to_branch_traffic_enabled = true
  tags                   = merge(var.tags, { region = each.key })
}

data "azurerm_virtual_hub" "vhub_existing" {
  # Look up a hub only for regions where create_hub is false.
  for_each = {
    for k, v in var.regional_config : k => v if !v.create_hub
  }

  name                = each.value.existing_hub_name
  resource_group_name = local.rg_name
}

# -----------------------------------------------------------------
# VIRTUAL HUB CONNECTION
# -----------------------------------------------------------------
resource "azurerm_virtual_hub_connection" "hub_connection" {
  for_each = local.all_hubs

  name                      = "${data.azurerm_virtual_network.cato_vnet[each.key].name}-to-${each.value.name}"
  virtual_hub_id            = each.value.id
  remote_virtual_network_id = data.azurerm_virtual_network.cato_vnet[each.key].id

  routing {
    associated_route_table_id = each.value.default_route_table_id
    propagated_route_table {
      labels          = ["default"]
      route_table_ids = [each.value.default_route_table_id]
    }
  }
}

# -----------------------------------------------------------------
# CATO ROUTED NETWORK FOR VWAN HUB SUBNET
# Informs the Cato site how to reach the vWAN Hub subnet.
# -----------------------------------------------------------------
resource "cato_network_range" "hub_routed_range" {
  for_each = local.all_hubs

  site_id         = cato_socket_site.azure-site[each.key].id
  name            = "${var.prefix}-hub-route-${each.key}"
  range_type      = "Routed"
  subnet          = each.value.address_prefix
  interface_index = "LAN1"
  gateway         = cidrhost(var.regional_config[each.key].subnet_range_lan, 1)
}

# -----------------------------------------------------------------
# AZURE VIRTUAL HUB BGP CONNECTION (NVA Peering)
# Creates BGP peering from Azure vWAN hub to Cato vSocket
# Note: Azure vWAN hubs always use ASN 65515 (Microsoft fixed value)
# -----------------------------------------------------------------
resource "azurerm_virtual_hub_bgp_connection" "nva_peering" {
  for_each = local.all_hubs

  name                          = "${var.prefix}-${each.key}-az-bgp-peer"
  virtual_hub_id                = each.value.id
  peer_asn                      = var.cato_bgp_asn # Cato side ASN (must not be 65515)
  peer_ip                       = var.regional_config[each.key].floating_ip
  virtual_network_connection_id = azurerm_virtual_hub_connection.hub_connection[each.key].id
}
