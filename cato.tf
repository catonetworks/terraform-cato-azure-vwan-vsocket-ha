resource "cato_socket_site" "azure-site" {
  for_each = var.regional_config

  connection_type = "SOCKET_AZ1500"
  description     = each.value.site_description
  name            = each.value.site_name
  native_range = {
    native_network_range = each.value.native_network_range
    local_ip             = azurerm_network_interface.lan-nic-primary[each.key].private_ip_address
  }
  site_location = {
    city         = local.cur_site_location[each.key].city
    country_code = local.cur_site_location[each.key].country_code
    state_code   = local.cur_site_location[each.key].state_code
    timezone     = local.cur_site_location[each.key].timezone
  }
  site_type = each.value.site_type

  lifecycle {
    ignore_changes = [native_range.local_ip] #Floating IP expected to Change depending on Active Config
  }
}

resource "cato_license" "license" {
  for_each = {
    for k, v in var.regional_config : k => v if v.license_id != null
  }

  depends_on = [null_resource.reboot_vsocket_secondary]
  site_id    = cato_socket_site.azure-site[each.key].id
  license_id = each.value.license_id
  bw         = each.value.license_bw
}

# Flattened routed networks for all regions
locals {
  regional_routed_networks = flatten([
    for region_key, region_config in var.regional_config : [
      for network_key, network_config in region_config.routed_networks : {
        key                = "${region_key}-${network_key}"
        region_key         = region_key
        network_key        = network_key
        network_config     = network_config
        site_id            = cato_socket_site.azure-site[region_key].id
        enable_translation = region_config.enable_static_range_translation
        lan_first_ip       = cidrhost(region_config.subnet_range_lan, 1)
      }
    ]
  ])
}

resource "cato_network_range" "routedAzure" {
  for_each = {
    for net in local.regional_routed_networks : net.key => net
  }

  site_id           = each.value.site_id
  name              = each.value.network_key
  range_type        = "Routed"
  gateway           = coalesce(each.value.network_config.gateway, each.value.lan_first_ip)
  interface_index   = each.value.network_config.interface_index
  subnet            = each.value.network_config.subnet
  translated_subnet = each.value.enable_translation ? coalesce(each.value.network_config.translated_subnet, each.value.network_config.subnet) : null
}

# -----------------------------------------------------------------
# CATO BGP PEER CONFIGURATION
# Creates BGP peers on Cato side connecting to Azure vWAN hubs
# Azure vWAN hubs always use ASN 65515 (each.value.peer_asn = 65515)
# Dual peers are created automatically for redundancy
# -----------------------------------------------------------------
resource "cato_bgp_peer" "vwan_peering" {
  for_each = { for peer in local.cato_bgp_peers : "${peer.location_name}-${peer.peer_type}" => peer }

  site_id                  = each.value.site_id
  name                     = "${var.prefix}-vwan-${each.key}-peer"
  cato_asn                 = var.cato_bgp_asn    # Your private ASN
  peer_asn                 = each.value.peer_asn # Azure vWAN ASN (always 65515)
  peer_ip                  = each.value.peer_ip  # vWAN hub router IP
  bfd_enabled              = var.cato_bgp_peer_config[each.value.peer_type].bfd_enabled
  metric                   = var.cato_bgp_peer_config[each.value.peer_type].metric
  default_action           = var.cato_bgp_peer_config[each.value.peer_type].default_action
  advertise_all_routes     = var.cato_bgp_peer_config[each.value.peer_type].advertise_all_routes
  advertise_default_route  = var.cato_bgp_peer_config[each.value.peer_type].advertise_default_route
  advertise_summary_routes = var.cato_bgp_peer_config[each.value.peer_type].advertise_summary_routes
  md5_auth_key             = ""

  lifecycle {
    #Ignoring bfd_settings as they are not supported via Socket, but API still references them.
    ignore_changes = [summary_route, bfd_settings]
  }

  depends_on = [cato_network_range.hub_routed_range]
}