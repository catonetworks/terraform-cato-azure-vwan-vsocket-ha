# ##Regional outputs - all resources are deployed across multiple regions

# Cato Socket Site Outputs - Regional Map
output "cato_site_id" {
  description = "Map of region to Cato Socket Site ID"
  value       = { for k, site in cato_socket_site.azure-site : k => site.id }
}

output "cato_site_name" {
  description = "Map of region to Cato Site Name"
  value       = { for k, site in cato_socket_site.azure-site : k => site.name }
}

output "cato_primary_serial" {
  description = "Map of region to Primary Cato Socket Serial Number"
  value       = { for k, serial in local.primary_serial : k => try(serial[0], "N/A") }
}

output "cato_secondary_serial" {
  description = "Map of region to Secondary Cato Socket Serial Number"
  value       = { for k, serial in local.secondary_serial : k => try(serial[0], "N/A") }
}

# Virtual Machine Outputs - Regional Maps
output "vsocket_primary_vm_id" {
  description = "Map of region to Primary vSocket Virtual Machine ID"
  value       = { for k, vm in azurerm_linux_virtual_machine.vsocket_primary : k => vm.id }
}

output "vsocket_primary_vm_name" {
  description = "Map of region to Primary vSocket Virtual Machine Name"
  value       = { for k, vm in azurerm_linux_virtual_machine.vsocket_primary : k => vm.name }
}

output "vsocket_secondary_vm_id" {
  description = "Map of region to Secondary vSocket Virtual Machine ID"
  value       = { for k, vm in azurerm_linux_virtual_machine.vsocket_secondary : k => vm.id }
}

output "vsocket_secondary_vm_name" {
  description = "Map of region to Secondary vSocket Virtual Machine Name"
  value       = { for k, vm in azurerm_linux_virtual_machine.vsocket_secondary : k => vm.name }
}

# User Assigned Identity - Regional Maps
output "ha_identity_id" {
  description = "Map of region to User Assigned Identity ID for HA"
  value       = { for k, identity in azurerm_user_assigned_identity.CatoHaIdentity : k => identity.id }
}

output "ha_identity_principal_id" {
  description = "Map of region to Principal ID of the HA Identity"
  value       = { for k, identity in azurerm_user_assigned_identity.CatoHaIdentity : k => identity.principal_id }
}

# Role Assignments Outputs - Regional Maps
output "primary_nic_role_assignment_id" {
  description = "Map of region to Role Assignment ID for the Primary NIC"
  value       = { for k, role in azurerm_role_assignment.primary_nic_ha_role : k => role.id }
}

output "secondary_nic_role_assignment_id" {
  description = "Map of region to Role Assignment ID for the Secondary NIC"
  value       = { for k, role in azurerm_role_assignment.secondary_nic_ha_role : k => role.id }
}

output "lan_subnet_role_assignment_id" {
  description = "Map of region to Role Assignment ID for the LAN Subnet"
  value       = { for k, role in azurerm_role_assignment.lan-subnet-role : k => role.id }
}

# Reboot Status Outputs - Regional Maps
output "vsocket_primary_reboot_status" {
  description = "Map of region to Status of the Primary vSocket VM Reboot"
  value       = { for k, v in var.regional_config : k => "Reboot triggered via Terraform" }
  depends_on  = [null_resource.reboot_vsocket_primary]
}

output "vsocket_secondary_reboot_status" {
  description = "Map of region to Status of the Secondary vSocket VM Reboot"
  value       = { for k, v in var.regional_config : k => "Reboot triggered via Terraform" }
  depends_on  = [null_resource.reboot_vsocket_secondary]
}

# Network Interface Outputs - Regional Maps

output "mgmt_nic_name_primary" {
  description = "Map of region to primary management network interface name"
  value       = { for k, nic in azurerm_network_interface.mgmt-nic-primary : k => nic.name }
}

output "wan_nic_name_primary" {
  description = "Map of region to primary WAN network interface name"
  value       = { for k, nic in azurerm_network_interface.wan-nic-primary : k => nic.name }
}

output "lan_nic_name_primary" {
  description = "Map of region to primary LAN network interface name"
  value       = { for k, nic in azurerm_network_interface.lan-nic-primary : k => nic.name }
}

output "mgmt_nic_name_secondary" {
  description = "Map of region to secondary management network interface name for HA"
  value       = { for k, nic in azurerm_network_interface.mgmt-nic-secondary : k => nic.name }
}

output "wan_nic_name_secondary" {
  description = "Map of region to secondary WAN network interface name for HA"
  value       = { for k, nic in azurerm_network_interface.wan-nic-secondary : k => nic.name }
}

output "lan_nic_name_secondary" {
  description = "Map of region to secondary LAN network interface name for HA"
  value       = { for k, nic in azurerm_network_interface.lan-nic-secondary : k => nic.name }
}

output "lan_subnet_id" {
  description = "Map of region to LAN subnet ID within the virtual network"
  value       = { for k, subnet in azurerm_subnet.subnet-lan : k => subnet.id }
}

output "vnet_name" {
  description = "Map of region to Azure Virtual Network name used by the deployment"
  value = { for k, config in var.regional_config : k =>
    config.vnet_name == null ? azurerm_virtual_network.vnet[k].name : config.vnet_name
  }
}

output "lan_subnet_name" {
  description = "Map of region to LAN subnet name within the virtual network"
  value       = { for k, subnet in azurerm_subnet.subnet-lan : k => subnet.name }
}

# Network Interface ID Outputs - Regional Maps
output "mgmt_primary_nic_id" {
  description = "Map of region to Management Primary Network Interface ID"
  value       = { for k, nic in azurerm_network_interface.mgmt-nic-primary : k => nic.id }
}

output "wan_primary_nic_id" {
  description = "Map of region to WAN Primary Network Interface ID"
  value       = { for k, nic in azurerm_network_interface.wan-nic-primary : k => nic.id }
}

output "lan_primary_nic_id" {
  description = "Map of region to LAN Primary Network Interface ID"
  value       = { for k, nic in azurerm_network_interface.lan-nic-primary : k => nic.id }
}

output "mgmt_secondary_nic_id" {
  description = "Map of region to Management Secondary Network Interface ID"
  value       = { for k, nic in azurerm_network_interface.mgmt-nic-secondary : k => nic.id }
}

output "wan_secondary_nic_id" {
  description = "Map of region to WAN Secondary Network Interface ID"
  value       = { for k, nic in azurerm_network_interface.wan-nic-secondary : k => nic.id }
}

output "lan_secondary_nic_id" {
  description = "Map of region to LAN Secondary Network Interface ID"
  value       = { for k, nic in azurerm_network_interface.lan-nic-secondary : k => nic.id }
}

# LAN MAC Address Output - Regional Map
output "lan_secondary_mac_address" {
  description = "Map of region to MAC Address of the Secondary LAN Interface"
  value       = { for k, nic in data.azurerm_network_interface.lan-mac-secondary : k => nic.mac_address }
}

# Global Infrastructure Outputs
output "resource_group_name" {
  description = "The name of the resource group used for the deployment"
  value       = local.rg_name
}

output "virtual_wan_id" {
  description = "The resource ID of the Virtual WAN used for the deployment"
  value       = local.vwan_id
}

output "virtual_hub_details" {
  description = "Details of the deployed or referenced Virtual Hubs, including BGP peering info"
  value = { for k, hub in local.all_hubs : k => {
    name                   = hub.name
    id                     = hub.id
    location               = hub.location
    asn                    = hub.virtual_router_asn
    bgp_peering_ips        = hub.virtual_router_ips
    hub_routing_preference = try(hub.hub_routing_preference, "ASPath")
    }
  }
}

# Comprehensive Regional Summary
output "regional_deployment_summary" {
  description = "Comprehensive summary of all regional deployments with key identifiers"
  value = { for k, config in var.regional_config : k => {
    # Region Info
    region   = k
    location = config.location

    # Cato Resources
    cato_site_id          = cato_socket_site.azure-site[k].id
    cato_site_name        = cato_socket_site.azure-site[k].name
    cato_primary_serial   = try(local.primary_serial[k][0], "N/A")
    cato_secondary_serial = try(local.secondary_serial[k][0], "N/A")

    # Virtual Machines
    primary_vm_id     = azurerm_linux_virtual_machine.vsocket_primary[k].id
    primary_vm_name   = azurerm_linux_virtual_machine.vsocket_primary[k].name
    secondary_vm_id   = azurerm_linux_virtual_machine.vsocket_secondary[k].id
    secondary_vm_name = azurerm_linux_virtual_machine.vsocket_secondary[k].name

    # Networking
    vnet_name              = config.vnet_name == null ? azurerm_virtual_network.vnet[k].name : config.vnet_name
    lan_subnet_id          = azurerm_subnet.subnet-lan[k].id
    lan_nic_name_primary   = azurerm_network_interface.lan-nic-primary[k].name
    lan_nic_name_secondary = azurerm_network_interface.lan-nic-secondary[k].name

    # Identity
    ha_identity_id = azurerm_user_assigned_identity.CatoHaIdentity[k].id

    # IP Configuration
    floating_ip      = config.floating_ip
    lan_ip_primary   = config.lan_ip_primary
    lan_ip_secondary = config.lan_ip_secondary
    }
  }
  sensitive = true
}

output "cato_bgp_peer_details" {
  description = "Details of the configured Cato BGP peers."
  value = { for key, peer in cato_bgp_peer.vwan_peering : key => {
    name     = peer.name
    id       = peer.id
    site_id  = peer.site_id
    cato_asn = peer.cato_asn
    peer_asn = peer.peer_asn
    peer_ip  = peer.peer_ip
    metric   = peer.metric
    }
  }
}

output "azure_bgp_connection_details" {
  description = "Details of the BGP connections configured on the Azure Virtual Hub."
  value = { for key, conn in azurerm_virtual_hub_bgp_connection.nva_peering : key => {
    name     = conn.name
    id       = conn.id
    peer_ip  = conn.peer_ip
    peer_asn = conn.peer_asn
    }
  }
}