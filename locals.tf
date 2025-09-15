locals {
  # Regional lan first IP calculations
  lan_first_ip = {
    for region_key, region_config in var.regional_config :
    region_key => cidrhost(region_config.subnet_range_lan, 1)
  }

  # Regional primary serial numbers
  primary_serial = {
    for region_key, region_config in var.regional_config :
    region_key => [for s in data.cato_accountSnapshotSite.azure-site[region_key].info.sockets : s.serial if s.is_primary == true]
  }

  # Regional secondary serial numbers
  secondary_serial = {
    for region_key, region_config in var.regional_config :
    region_key => [for s in data.cato_accountSnapshotSite.azure-site-secondary[region_key].info.sockets : s.serial if s.is_primary == false]
  }

  # Determine the name of the resource group to use.
  rg_name = var.create_resource_group ? azurerm_resource_group.rg[0].name : data.azurerm_resource_group.existing_rg[0].name

  # Determine the ID of the Virtual WAN to use.
  vwan_id = var.create_vwan ? azurerm_virtual_wan.vwan[0].id : data.azurerm_virtual_wan.existing_vwan[0].id

  # Combine newly created and existing hub details into a single map for iteration.
  all_hubs = merge(
    azurerm_virtual_hub.vhub_new,
    data.azurerm_virtual_hub.vhub_existing
  )

  # Defines the list of BGP peers to create on the Cato side.
  # Both primary and secondary peers are always created for redundancy.
  # Azure vWAN hub.virtual_router_asn is always 65515 (Microsoft fixed value)
  # Only create BGP peers for hubs that have virtual_router_ips populated (length >= 2)
  cato_bgp_peers = flatten([
    for r_key, hub in local.all_hubs : length(hub.virtual_router_ips) >= 2 ? [
      # Primary BGP peer to first vWAN hub router IP
      {
        location_name = r_key
        peer_type     = "primary"
        peer_ip       = hub.virtual_router_ips[0]
        site_id       = cato_socket_site.azure-site[r_key].id
        peer_asn      = hub.virtual_router_asn # Always 65515 for Azure vWAN hubs
      },
      # Secondary BGP peer to second vWAN hub router IP (always created)
      {
        location_name = r_key
        peer_type     = "secondary"
        peer_ip       = hub.virtual_router_ips[1]
        site_id       = cato_socket_site.azure-site[r_key].id
        peer_asn      = hub.virtual_router_asn # Always 65515 for Azure vWAN hubs
      }
    ] : []
  ])
}
