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

  # --- NEW: Multi-Resource Group Logic ---
  
  # Determine vWAN resource group name
  vwan_rg_name = (
    # New configuration takes precedence
    var.vwan_resource_group != null ?
      (var.vwan_resource_group.create_new ? var.vwan_resource_group.name : var.vwan_resource_group.use_existing) :
    # Fall back to legacy configuration for backward compatibility
    var.create_resource_group ? var.resource_group_name :
    (var.existing_resource_group_name != "" ? var.existing_resource_group_name : "ERROR-NO-RG-SPECIFIED")
  )
  
  # Determine vHub resource group names (per region)
  vhub_rg_names = {
    for region_key, region_config in var.regional_config :
    region_key => (
      region_config.vhub_resource_group.strategy == "use_vwan_rg" ? local.vwan_rg_name :
      region_config.vhub_resource_group.name
    )
  }
  
  # Determine Cato resource group names (per region)
  cato_rg_names = {
    for region_key, region_config in var.regional_config :
    region_key => (
      # If cato_resource_group.name is null, fall back to legacy behavior (use vWAN RG)
      region_config.cato_resource_group.name != null ?
        region_config.cato_resource_group.name :
        local.vwan_rg_name
    )
  }
  
  # --- DEPRECATED: Legacy resource group name (for backward compatibility) ---
  # This maintains the original behavior for existing resources that haven't been updated yet
  rg_name = local.vwan_rg_name

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
    for r_key, hub in local.all_hubs : [
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
    ] 
  ])
}
