## Create random strings for auth, as a socket does not allow auth but the instance requires it
resource "random_string" "vsocket-random-username" {
  for_each = var.regional_config

  length  = 16
  special = false
}

resource "random_string" "vsocket-random-password" {
  for_each = var.regional_config

  length  = 16
  special = false
  upper   = true
  lower   = true
  numeric = true
}

# -----------------------------------------------------------------
# RESOURCE GROUPS (Multi-Resource Group Structure)
# -----------------------------------------------------------------

# vWAN Resource Group (conditional)
resource "azurerm_resource_group" "vwan_rg" {
  count = (
    # New configuration takes precedence
    var.vwan_resource_group != null ?
    (var.vwan_resource_group.create_new ? 1 : 0) :
    # Fall back to legacy configuration for backward compatibility 
    var.create_resource_group ? 1 : 0
  )

  name     = local.vwan_rg_name
  location = var.primary_location
  tags     = var.tags
}

# vHub Resource Groups (conditional, per region)
resource "azurerm_resource_group" "vhub_rg" {
  for_each = {
    for region_key, region_config in var.regional_config :
    region_key => region_config
    if region_config.vhub_resource_group.strategy == "create_new"
  }

  name     = each.value.vhub_resource_group.name
  location = each.value.location
  tags = merge(var.tags, {
    region        = each.key
    resource_type = "vhub"
  })
}

# Cato Resource Groups (conditional, per region or shared)
resource "azurerm_resource_group" "cato_rg" {
  for_each = {
    for region_key, region_config in var.regional_config :
    region_config.cato_resource_group.name => {
      name       = region_config.cato_resource_group.name
      location   = region_config.location
      strategy   = region_config.cato_resource_group.strategy
      region_key = region_key
    }
    # Only create RG if name is not null (not legacy fallback) and meets creation criteria
    if region_config.cato_resource_group.name != null && (
      region_config.cato_resource_group.strategy == "create_new" ||
      (
        region_config.cato_resource_group.strategy == "use_shared" &&
        # For shared strategy, only create one RG by selecting the first region alphabetically 
        region_key == keys({
          for k, v in var.regional_config : k => v
          if v.cato_resource_group.name == region_config.cato_resource_group.name &&
          v.cato_resource_group.strategy == "use_shared"
        })[0]
      )
    )
  }

  name     = each.value.name
  location = each.value.location
  tags = merge(var.tags, {
    resource_type = "cato"
    strategy      = each.value.strategy
  })
}

# --- DEPRECATED: Legacy Resource Group (for backward compatibility) ---
# This resource is kept for backward compatibility but will use the same logic as vWAN RG
resource "azurerm_resource_group" "rg" {
  count = 0 # Disabled - functionality moved to vwan_rg

  name     = var.resource_group_name
  location = var.primary_location
  tags     = var.tags
}

resource "azurerm_availability_set" "availability-set" {
  for_each = var.regional_config

  location                     = each.value.location
  name                         = replace(replace("${var.prefix}-${each.key}-availabilitySet", "-", "_"), " ", "_")
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  resource_group_name          = local.cato_rg_names[each.key]
  tags                         = merge(var.tags, { region = each.key })
}

## Create Network and Subnets
resource "azurerm_virtual_network" "vnet" {
  for_each = {
    for k, v in var.regional_config : k => v if v.vnet_name == null
  }

  address_space       = [each.value.vnet_network_range]
  location            = each.value.location
  name                = replace(replace("${var.prefix}-${each.key}-vsNet", "-", "_"), " ", "_")
  resource_group_name = local.cato_rg_names[each.key]
  tags                = merge(var.tags, { region = each.key })
}

resource "azurerm_virtual_network_dns_servers" "dns_servers" {
  for_each = var.regional_config

  virtual_network_id = each.value.vnet_name == null ? azurerm_virtual_network.vnet[each.key].id : data.azurerm_virtual_network.custom-vnet[each.key].id
  dns_servers        = each.value.dns_servers
}

resource "azurerm_subnet" "subnet-mgmt" {
  for_each = var.regional_config

  address_prefixes     = [each.value.subnet_range_mgmt]
  name                 = replace(replace("${var.prefix}-${each.key}-subnetMGMT", "-", "_"), " ", "_")
  resource_group_name  = local.cato_rg_names[each.key]
  virtual_network_name = replace(replace("${var.prefix}-${each.key}-vsNet", "-", "_"), " ", "_")
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet-wan" {
  for_each = var.regional_config

  address_prefixes     = [each.value.subnet_range_wan]
  name                 = replace(replace("${var.prefix}-${each.key}-subnetWAN", "-", "_"), " ", "_")
  resource_group_name  = local.cato_rg_names[each.key]
  virtual_network_name = replace(replace("${var.prefix}-${each.key}-vsNet", "-", "_"), " ", "_")
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet-lan" {
  for_each = var.regional_config

  address_prefixes     = [each.value.subnet_range_lan]
  name                 = replace(replace("${var.prefix}-${each.key}-subnetLAN", "-", "_"), " ", "_")
  resource_group_name  = local.cato_rg_names[each.key]
  virtual_network_name = replace(replace("${var.prefix}-${each.key}-vsNet", "-", "_"), " ", "_")
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# Allocate Public IPs
resource "azurerm_public_ip" "mgmt-public-ip-primary" {
  for_each = var.regional_config

  allocation_method   = "Static"
  location            = each.value.location
  name                = replace(replace("${var.prefix}-${each.key}-mngPublicIPPrimary", "-", "_"), " ", "_")
  resource_group_name = local.cato_rg_names[each.key]
  sku                 = "Standard"
  tags                = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_public_ip" "wan-public-ip-primary" {
  for_each = var.regional_config

  allocation_method   = "Static"
  location            = each.value.location
  name                = replace(replace("${var.prefix}-${each.key}-wanPublicIPPrimary", "-", "_"), " ", "_")
  resource_group_name = local.cato_rg_names[each.key]
  sku                 = "Standard"
  tags                = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_public_ip" "mgmt-public-ip-secondary" {
  for_each = var.regional_config

  allocation_method   = "Static"
  location            = each.value.location
  name                = replace(replace("${var.prefix}-${each.key}-mngPublicIPSecondary", "-", "_"), " ", "_")
  resource_group_name = local.cato_rg_names[each.key]
  sku                 = "Standard"
  tags                = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_public_ip" "wan-public-ip-secondary" {
  for_each = var.regional_config

  allocation_method   = "Static"
  location            = each.value.location
  name                = replace(replace("${var.prefix}-${each.key}-wanPublicIPSecondary", "-", "_"), " ", "_")
  resource_group_name = local.cato_rg_names[each.key]
  sku                 = "Standard"
  tags                = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

# Create Network Interfaces
resource "azurerm_network_interface" "mgmt-nic-primary" {
  for_each = var.regional_config

  location            = each.value.location
  name                = "${var.prefix}-${each.key}-mngPrimary"
  resource_group_name = local.cato_rg_names[each.key]
  ip_configuration {
    name                          = replace(replace("${var.prefix}-${each.key}-mgmtIPPrimary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmt-public-ip-primary[each.key].id
    subnet_id                     = azurerm_subnet.subnet-mgmt[each.key].id
  }
  tags = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_public_ip.mgmt-public-ip-primary,
    azurerm_subnet.subnet-mgmt
  ]
}

resource "azurerm_network_interface" "wan-nic-primary" {
  for_each = var.regional_config

  ip_forwarding_enabled = true
  location              = each.value.location
  name                  = "${var.prefix}-${each.key}-wanPrimary"
  resource_group_name   = local.cato_rg_names[each.key]
  ip_configuration {
    name                          = replace(replace("${var.prefix}-${each.key}-wanIPPrimary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wan-public-ip-primary[each.key].id
    subnet_id                     = azurerm_subnet.subnet-wan[each.key].id
  }
  tags = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_public_ip.wan-public-ip-primary,
    azurerm_subnet.subnet-wan
  ]
}

resource "azurerm_network_interface" "lan-nic-primary" {
  for_each = var.regional_config

  ip_forwarding_enabled = true
  location              = each.value.location
  name                  = "${var.prefix}-${each.key}-lanPrimary"
  resource_group_name   = local.cato_rg_names[each.key]
  ip_configuration {
    name                          = replace(replace("${var.prefix}-${each.key}-lanIPConfigPrimary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.lan_ip_primary
    subnet_id                     = azurerm_subnet.subnet-lan[each.key].id
  }
  tags = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_subnet.subnet-lan
  ]
  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_network_interface" "mgmt-nic-secondary" {
  for_each = var.regional_config

  location            = each.value.location
  name                = "${var.prefix}-${each.key}-mngSecondary"
  resource_group_name = local.cato_rg_names[each.key]
  ip_configuration {
    name                          = replace(replace("${var.prefix}-${each.key}-mgmtIPSecondary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mgmt-public-ip-secondary[each.key].id
    subnet_id                     = azurerm_subnet.subnet-mgmt[each.key].id
  }
  tags = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_public_ip.mgmt-public-ip-secondary,
    azurerm_subnet.subnet-mgmt
  ]
}

resource "azurerm_network_interface" "wan-nic-secondary" {
  for_each = var.regional_config

  ip_forwarding_enabled = true
  location              = each.value.location
  name                  = "${var.prefix}-${each.key}-wanSecondary"
  resource_group_name   = local.cato_rg_names[each.key]
  ip_configuration {
    name                          = replace(replace("${var.prefix}-${each.key}-wanIPSecondary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wan-public-ip-secondary[each.key].id
    subnet_id                     = azurerm_subnet.subnet-wan[each.key].id
  }
  tags = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_public_ip.wan-public-ip-secondary,
    azurerm_subnet.subnet-wan
  ]
}

resource "azurerm_network_interface" "lan-nic-secondary" {
  for_each = var.regional_config

  ip_forwarding_enabled = true
  location              = each.value.location
  name                  = "${var.prefix}-${each.key}-lanSecondary"
  resource_group_name   = local.cato_rg_names[each.key]
  ip_configuration {
    name                          = replace(replace("${var.prefix}-${each.key}-lanIPConfigSecondary", "-", "_"), " ", "_")
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.lan_ip_secondary
    subnet_id                     = azurerm_subnet.subnet-lan[each.key].id
  }
  tags = merge(var.tags, { region = each.key })
  depends_on = [
    azurerm_subnet.subnet-lan
  ]
}

resource "azurerm_subnet_network_security_group_association" "mgmt-association" {
  for_each = var.regional_config

  subnet_id                 = azurerm_subnet.subnet-mgmt[each.key].id
  network_security_group_id = azurerm_network_security_group.mgmt-sg[each.key].id
}

resource "azurerm_subnet_network_security_group_association" "wan-association" {
  for_each = var.regional_config

  subnet_id                 = azurerm_subnet.subnet-wan[each.key].id
  network_security_group_id = azurerm_network_security_group.wan-sg[each.key].id
}

resource "azurerm_subnet_network_security_group_association" "lan-association" {
  for_each = var.regional_config

  subnet_id                 = azurerm_subnet.subnet-lan[each.key].id
  network_security_group_id = azurerm_network_security_group.lan-sg[each.key].id
}

## Create Route Tables, Routes and Associations 
# IMPORTANT: BGP route propagation MUST be enabled on the Cato LAN route table
# to allow the Cato sockets to learn spoke vnet routes from the vWAN hub.
# Without this, return traffic from spoke vnets to Cato will fail.
resource "azurerm_route_table" "private-rt" {
  for_each = var.regional_config

  bgp_route_propagation_enabled = true # Enable BGP propagation for Cato connectivity
  location                      = each.value.location
  name                          = replace(replace("${var.prefix}-${each.key}-viaCato", "-", "_"), " ", "_")
  resource_group_name           = local.cato_rg_names[each.key]
  tags                          = merge(var.tags, { region = each.key })
}

resource "azurerm_route" "public-route-kms" {
  for_each = var.regional_config

  address_prefix      = "23.102.135.246/32" #
  name                = "Microsoft-KMS"
  next_hop_type       = "Internet"
  resource_group_name = local.cato_rg_names[each.key]
  route_table_name    = replace(replace("${var.prefix}-${each.key}-viaCato", "-", "_"), " ", "_")
  depends_on = [
    azurerm_route_table.private-rt
  ]
}

resource "azurerm_route" "lan-route" {
  for_each = var.regional_config

  address_prefix         = "0.0.0.0/0"
  name                   = "default-cato"
  next_hop_in_ip_address = each.value.floating_ip
  next_hop_type          = "VirtualAppliance"
  resource_group_name    = local.cato_rg_names[each.key]
  route_table_name       = replace(replace("${var.prefix}-${each.key}-viaCato", "-", "_"), " ", "_")
  depends_on = [
    azurerm_route_table.private-rt
  ]
}

resource "azurerm_route_table" "public-rt" {
  for_each = var.regional_config

  bgp_route_propagation_enabled = false
  location                      = each.value.location
  name                          = replace(replace("${var.prefix}-${each.key}-viaInternet", "-", "_"), " ", "_")
  resource_group_name           = local.cato_rg_names[each.key]
  tags                          = merge(var.tags, { region = each.key })
}

resource "azurerm_route" "internet-route" {
  for_each = var.regional_config

  address_prefix      = "0.0.0.0/0"
  name                = "default-internet"
  next_hop_type       = "Internet"
  resource_group_name = local.cato_rg_names[each.key]
  route_table_name    = replace(replace("${var.prefix}-${each.key}-viaInternet", "-", "_"), " ", "_")
  depends_on = [
    azurerm_route_table.public-rt
  ]
}

resource "azurerm_subnet_route_table_association" "rt-table-association-mgmt" {
  for_each = var.regional_config

  route_table_id = azurerm_route_table.public-rt[each.key].id
  subnet_id      = azurerm_subnet.subnet-mgmt[each.key].id
  depends_on = [
    azurerm_route_table.public-rt,
    azurerm_subnet.subnet-mgmt
  ]
}

resource "azurerm_subnet_route_table_association" "rt-table-association-wan" {
  for_each = var.regional_config

  route_table_id = azurerm_route_table.public-rt[each.key].id
  subnet_id      = azurerm_subnet.subnet-wan[each.key].id
  depends_on = [
    azurerm_route_table.public-rt,
    azurerm_subnet.subnet-wan,
  ]
}

resource "azurerm_subnet_route_table_association" "rt-table-association-lan" {
  for_each = var.regional_config

  route_table_id = azurerm_route_table.private-rt[each.key].id
  subnet_id      = azurerm_subnet.subnet-lan[each.key].id
  depends_on = [
    azurerm_route_table.private-rt,
    azurerm_subnet.subnet-lan
  ]
}




