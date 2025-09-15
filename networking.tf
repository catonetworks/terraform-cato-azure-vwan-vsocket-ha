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
# RESOURCE GROUP (Conditional)
# -----------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  count = var.create_resource_group ? 1 : 0

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
  resource_group_name          = local.rg_name
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
  resource_group_name = local.rg_name
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
  resource_group_name  = local.rg_name
  virtual_network_name = replace(replace("${var.prefix}-${each.key}-vsNet", "-", "_"), " ", "_")
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet-wan" {
  for_each = var.regional_config

  address_prefixes     = [each.value.subnet_range_wan]
  name                 = replace(replace("${var.prefix}-${each.key}-subnetWAN", "-", "_"), " ", "_")
  resource_group_name  = local.rg_name
  virtual_network_name = replace(replace("${var.prefix}-${each.key}-vsNet", "-", "_"), " ", "_")
  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

resource "azurerm_subnet" "subnet-lan" {
  for_each = var.regional_config

  address_prefixes     = [each.value.subnet_range_lan]
  name                 = replace(replace("${var.prefix}-${each.key}-subnetLAN", "-", "_"), " ", "_")
  resource_group_name  = local.rg_name
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
  resource_group_name = local.rg_name
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
  resource_group_name = local.rg_name
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
  resource_group_name = local.rg_name
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
  resource_group_name = local.rg_name
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
  resource_group_name = local.rg_name
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
  resource_group_name   = local.rg_name
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
  resource_group_name   = local.rg_name
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
  resource_group_name = local.rg_name
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
  resource_group_name   = local.rg_name
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
  resource_group_name   = local.rg_name
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
resource "azurerm_route_table" "private-rt" {
  for_each = var.regional_config

  bgp_route_propagation_enabled = false
  location                      = each.value.location
  name                          = replace(replace("${var.prefix}-${each.key}-viaCato", "-", "_"), " ", "_")
  resource_group_name           = local.rg_name
  tags                          = merge(var.tags, { region = each.key })
}

resource "azurerm_route" "public-route-kms" {
  for_each = var.regional_config

  address_prefix      = "23.102.135.246/32" #
  name                = "Microsoft-KMS"
  next_hop_type       = "Internet"
  resource_group_name = local.rg_name
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
  resource_group_name    = local.rg_name
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
  resource_group_name           = local.rg_name
  tags                          = merge(var.tags, { region = each.key })
}

resource "azurerm_route" "internet-route" {
  for_each = var.regional_config

  address_prefix      = "0.0.0.0/0"
  name                = "default-internet"
  next_hop_type       = "Internet"
  resource_group_name = local.rg_name
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




