variable "commands-secondary" {
  type = list(string)
  default = [
    "nohup /cato/socket/run_socket_daemon.sh &"
  ]
}

variable "baseurl" {
  description = "Base URL for the Cato Networks API."
  type        = string
  default     = "https://api.catonetworks.com/api/v1/graphql2"
}

variable "site_description" {
  description = "(DEPRECATED) A brief description of the site for identification purposes. Use regional_config instead."
  type        = string
  default     = null
}

variable "site_type" {
  description = "(DEPRECATED) The type of the site (DATACENTER, BRANCH, CLOUD_DC, HEADQUARTERS). Use regional_config instead."
  type        = string
  default     = null
  validation {
    condition     = var.site_type == null || contains(["DATACENTER", "BRANCH", "CLOUD_DC", "HEADQUARTERS"], var.site_type)
    error_message = "The site_type variable must be one of 'DATACENTER','BRANCH','CLOUD_DC','HEADQUARTERS' or null."
  }
}

variable "site_name" {
  description = "(DEPRECATED) The name of the Cato Networks site. Use regional_config instead."
  type        = string
  default     = null
}

variable "site_location" {
  description = "Site location which is used by the Cato Socket to connect to the closest Cato PoP. If not specified, the location will be derived from the Azure region dynamicaly."
  type = object({
    city         = string
    country_code = string
    state_code   = string
    timezone     = string
  })
  default = {
    city         = null
    country_code = null
    state_code   = null ## Optional - for countries with states
    timezone     = null
  }
}

variable "native_network_range" {
  type        = string
  description = <<EOT
  	(DEPRECATED) Choose a unique range for your Azure environment that does not conflict with the rest of your Wide Area Network.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
    Use regional_config instead.
	EOT
  default     = null
}

variable "vm_size" {
  description = "(DEPRECATED) Specifies the size of the Virtual Machine. Use regional_config instead. See Azure VM Naming Conventions: https://learn.microsoft.com/en-us/azure/virtual-machines/vm-naming-conventions"
  type        = string
  default     = null
}

variable "disk_size_gb" {
  description = "Size of the managed disk in GB."
  type        = number
  default     = 8
  validation {
    condition     = var.disk_size_gb > 0
    error_message = "Disk size must be greater than 0."
  }
}

## VSocket Params - DEPRECATED: Use regional_config instead

variable "location" {
  description = "(DEPRECATED) The Azure region where the resources should be deployed. Use regional_config instead."
  type        = string
  default     = null
}

variable "floating_ip" {
  description = "(DEPRECATED) The floating IP address used for High Availability (HA) failover. Use regional_config instead."
  type        = string
  default     = null
}

variable "lan_subnet_name" {
  description = "(DEPRECATED) The name of the LAN subnet within the specified VNET. Use regional_config instead."
  type        = string
  default     = null
}

variable "commands" {
  type = list(string)
  default = [
    "rm /cato/deviceid.txt",
    "rm /cato/socket/configuration/socket_registration.json",
    "nohup /cato/socket/run_socket_daemon.sh &"
  ]
}

## VNET Variables - DEPRECATED: Use regional_config instead
variable "lan_ip_primary" {
  type        = string
  description = "(DEPRECATED) Local IP Address of socket LAN interface. Use regional_config instead."
  default     = null
}

variable "lan_ip_secondary" {
  type        = string
  description = "(DEPRECATED) Local IP Address of socket LAN interface. Use regional_config instead."
  default     = null
}

variable "dns_servers" {
  type = list(string)
  default = [
    "168.63.129.16", # Azure DNS
    "10.254.254.1",  # Cato Cloud DNS
    "1.1.1.1",
    "8.8.8.8"
  ]
}

variable "subnet_range_mgmt" {
  type        = string
  description = <<EOT
    (DEPRECATED) Choose a range within the VPC to use as the Management subnet. Use regional_config instead.
    This subnet will be used initially to access the public internet and register your vSocket to the Cato Cloud.
    The minimum subnet length to support High Availability is /28.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}

variable "subnet_range_wan" {
  type        = string
  description = <<EOT
    (DEPRECATED) Choose a range within the VPC to use as the Public/WAN subnet. Use regional_config instead.
    This subnet will be used to access the public internet and securely tunnel to the Cato Cloud.
    The minimum subnet length to support High Availability is /28.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}

variable "subnet_range_lan" {
  type        = string
  description = <<EOT
    (DEPRECATED) Choose a range within the VPC to use as the Private/LAN subnet. Use regional_config instead.
    This subnet will host the target LAN interface of the vSocket so resources in the VPC (or AWS Region) can route to the Cato Cloud.
    The minimum subnet length to support High Availability is /29.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}
variable "vnet_network_range" {
  type        = string
  description = <<EOT
  	(DEPRECATED) Choose a unique range for your new VPC that does not conflict with the rest of your Wide Area Network. Use regional_config instead.
    The accepted input format is Standard CIDR Notation, e.g. X.X.X.X/X
	EOT
  default     = null
}

variable "image_reference_id" {
  description = "The path to the image used to deploy a specific version of the virtual socket."
  type        = string
  default     = "/Subscriptions/38b5ec1d-b3b6-4f50-a34e-f04a67121955/Providers/Microsoft.Compute/Locations/eastus/Publishers/catonetworks/ArtifactTypes/VMImage/Offers/cato_socket/Skus/public-cato-socket/Versions/19.0.17805"
}

variable "license_id" {
  description = "The license ID for the Cato vSocket of license type CATO_SITE, CATO_SSE_SITE, CATO_PB, CATO_PB_SSE.  Example License ID value: 'abcde123-abcd-1234-abcd-abcde1234567'.  Note that licenses are for commercial accounts, and not supported for trial accounts."
  type        = string
  default     = null
}

variable "license_bw" {
  description = "The license bandwidth number for the cato site, specifying bandwidth ONLY applies for pooled licenses.  For a standard site license that is not pooled, leave this value null. Must be a number greater than 0 and an increment of 10."
  type        = string
  default     = null
}

variable "vnet_name" {
  description = <<EOF
  (Optional) if a custom VNET ID is passed we will use the custom VNET, otherwise we will build one.
  EOF
  default     = null
}

variable "enable_static_range_translation" {
  description = "Enables the ability to use translated ranges"
  type        = string
  default     = false
}

variable "routed_networks" {
  description = <<EOF
  A map of routed networks to be accessed behind the vSocket site.
  - The key is the logical name for the network.
  - The value is an object containing:
    - "subnet" (string, required): The actual CIDR range of the network.
    - "translated_subnet" (string, optional): The NATed CIDR range if translation is used.
  Example: 
  routed_networks = {
    "Peered-VNET-1" = {
      subnet = "10.100.1.0/24"
    }
    "On-Prem-Network-NAT" = {
      subnet            = "192.168.51.0/24"
      translated_subnet = "10.200.1.0/24"
    }
  }
  EOF
  type = map(object({
    subnet            = string
    translated_subnet = optional(string)
    gateway           = optional(string)
    interface_index   = optional(string, "LAN1")
  }))
  default = {}
}


variable "prefix" {
  description = "A prefix to be used for naming all resources."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.prefix)) && length(var.prefix) >= 2 && length(var.prefix) <= 24
    error_message = "Prefix must be 2-24 characters, start and end with alphanumeric characters, and contain only letters, numbers, and hyphens."
  }
}

variable "primary_location" {
  description = "The primary Azure region to deploy shared resources like the vWAN and Resource Group."
  type        = string

  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3", "Central US", "North Central US", "South Central US", "West Central US",
      "North Europe", "West Europe", "France Central", "France South", "Germany West Central", "Germany North", "Norway East", "Norway West",
      "Sweden Central", "Switzerland North", "Switzerland West", "UK South", "UK West", "Poland Central",
      "Canada Central", "Canada East", "Brazil South", "South Africa North", "South Africa West",
      "Australia East", "Australia Southeast", "Australia Central", "Australia Central 2", "Central India", "South India", "West India", "Jio India Central", "Jio India West",
      "Japan East", "Japan West", "Korea Central", "Korea South", "East Asia", "Southeast Asia",
      "UAE North", "UAE Central", "Qatar Central"
    ], var.primary_location)
    error_message = "Primary location must be a valid Azure region display name. Common regions include: East US, East US 2, West US 2, West Europe, North Europe, etc."
  }
}

variable "create_resource_group" {
  description = "Set to true to create a new resource group. If false, existing_resource_group_name must be provided."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "The name of the Azure Resource Group to create. Only used if create_resource_group is true."
  type        = string
  default     = "cato-vwan-rg"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()-]+[^.]$", var.resource_group_name)) && length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "Resource group name must be 1-90 characters, can contain letters, numbers, underscores, hyphens, periods, and parentheses, and cannot end with a period."
  }
}

variable "existing_resource_group_name" {
  description = "The name of an existing resource group to use. Only used if create_resource_group is false."
  type        = string
  default     = ""

  validation {
    condition     = var.existing_resource_group_name == "" || (can(regex("^[a-zA-Z0-9._()-]+[^.]$", var.existing_resource_group_name)) && length(var.existing_resource_group_name) >= 1 && length(var.existing_resource_group_name) <= 90)
    error_message = "Existing resource group name must be empty or 1-90 characters, can contain letters, numbers, underscores, hyphens, periods, and parentheses, and cannot end with a period."
  }
}

variable "create_vwan" {
  description = "Set to true to create a new Virtual WAN. If false, existing_vwan_name must be provided."
  type        = bool
  default     = true
}

variable "existing_vwan_name" {
  description = "The name of an existing Virtual WAN to use. Only used if create_vwan is false."
  type        = string
  default     = ""

  validation {
    condition     = var.existing_vwan_name == "" || (can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9]$", var.existing_vwan_name)) && length(var.existing_vwan_name) >= 2 && length(var.existing_vwan_name) <= 80)
    error_message = "Existing Virtual WAN name must be empty or 2-80 characters, start and end with alphanumeric, and contain only letters, numbers, periods, underscores, and hyphens."
  }
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# --- Cato & Azure Authentication Variables ---

variable "cato_token" {
  description = "Cato Management API Token."
  type        = string
  sensitive   = true
}

variable "cato_account_id" {
  description = "Your Cato Account ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+$", var.cato_account_id)) && length(var.cato_account_id) >= 4 && length(var.cato_account_id) <= 10
    error_message = "Cato Account ID must be a numeric string between 4-10 digits."
  }
}

variable "azure_subscription_id" {
  description = "The Azure Subscription ID where resources will be deployed."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.azure_subscription_id))
    error_message = "Azure Subscription ID must be a valid GUID format (e.g., 12345678-1234-1234-1234-123456789012)."
  }
}

# --- Regional and Hub Configuration ---

variable "regional_config" {
  description = "A map containing specific configurations for each region."
  type = map(object({
    # --- Cato Module Inputs ---
    location                        = string
    native_network_range            = string
    vnet_network_range              = string
    subnet_range_mgmt               = string
    subnet_range_wan                = string
    subnet_range_lan                = string
    lan_ip_primary                  = string
    lan_ip_secondary                = string
    floating_ip                     = string
    site_name                       = string
    site_description                = optional(string, "Multi-regional Cato vSocket site")
    site_type                       = optional(string, "CLOUD_DC")
    vnet_name                       = optional(string)                # If null, creates new VNET, otherwise uses existing
    lan_subnet_name                 = optional(string, "subnet-lan")  # Used when vnet_name is specified
    mgmt_subnet_name                = optional(string, "subnet-mgmt") # Used when vnet_name is specified
    wan_subnet_name                 = optional(string, "subnet-wan")  # Used when vnet_name is specified
    vm_size                         = optional(string, "Standard_D8ls_v5")
    license_id                      = optional(string)
    license_bw                      = optional(string)
    dns_servers                     = optional(list(string), ["168.63.129.16", "10.254.254.1", "1.1.1.1", "8.8.8.8"])
    enable_static_range_translation = optional(bool, false)
    commands                        = optional(list(string), ["rm /cato/deviceid.txt", "rm /cato/socket/configuration/socket_registration.json", "nohup /cato/socket/run_socket_daemon.sh &"])
    routed_networks = optional(map(object({
      subnet            = string
      translated_subnet = optional(string)
      gateway           = optional(string)
      interface_index   = optional(string, "LAN1")
    })), {})
    site_location = optional(object({
      city         = optional(string)
      country_code = optional(string)
      state_code   = optional(string)
      timezone     = optional(string)
      }), {
      city         = null
      country_code = null
      state_code   = null
      timezone     = null
    })

    # --- Hub Creation/Lookup ---
    create_hub             = bool
    existing_hub_name      = optional(string)
    hub_address_prefix     = optional(string)
    hub_routing_preference = optional(string, "ASPath") # ASPath (default), ExpressRoute, or VpnGateway
  }))
  # Validate all locations are valid Azure regions
  validation {
    condition = alltrue([
      for config in values(var.regional_config) :
      contains([
        "East US", "East US 2", "West US", "West US 2", "West US 3", "Central US", "North Central US", "South Central US", "West Central US",
        "North Europe", "West Europe", "France Central", "France South", "Germany West Central", "Germany North", "Norway East", "Norway West",
        "Sweden Central", "Switzerland North", "Switzerland West", "UK South", "UK West", "Poland Central",
        "Canada Central", "Canada East", "Brazil South", "South Africa North", "South Africa West",
        "Australia East", "Australia Southeast", "Australia Central", "Australia Central 2", "Central India", "South India", "West India", "Jio India Central", "Jio India West",
        "Japan East", "Japan West", "Korea Central", "Korea South", "East Asia", "Southeast Asia",
        "UAE North", "UAE Central", "Qatar Central"
      ], config.location)
    ])
    error_message = "All regional_config locations must be valid Azure region display names. Use names like 'East US 2', 'West Central US', etc."
  }

  # Validate network ranges are in CIDR format
  validation {
    condition = alltrue([
      for config in values(var.regional_config) :
      can(cidrhost(config.native_network_range, 0)) &&
      can(cidrhost(config.vnet_network_range, 0)) &&
      can(cidrhost(config.subnet_range_mgmt, 0)) &&
      can(cidrhost(config.subnet_range_wan, 0)) &&
      can(cidrhost(config.subnet_range_lan, 0))
    ])
    error_message = "All network ranges must be valid CIDR notation (e.g., 10.0.0.0/16)."
  }

  # Validate IP addresses are valid IPv4
  validation {
    condition = alltrue([
      for config in values(var.regional_config) :
      can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", config.lan_ip_primary)) &&
      can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", config.lan_ip_secondary)) &&
      can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", config.floating_ip))
    ])
    error_message = "LAN IP addresses and floating IP must be valid IPv4 addresses."
  }

  # Validate country codes are ISO 3166-1 alpha-2 format (when provided)
  validation {
    condition = alltrue([
      for config in values(var.regional_config) :
      config.site_location.country_code == null || can(regex("^[A-Z]{2}$", config.site_location.country_code))
    ])
    error_message = "Country code must be a valid ISO 3166-1 alpha-2 code (e.g., US, GB, DE) when provided, or null to auto-derive from Azure region."
  }

  # Validate hub routing preference
  validation {
    condition = alltrue([
      for config in values(var.regional_config) :
      config.hub_routing_preference == null || contains(["ASPath", "ExpressRoute", "VpnGateway"], config.hub_routing_preference)
    ])
    error_message = "Hub routing preference must be one of: ASPath (default, best AS path), ExpressRoute (prioritize ExpressRoute), or VpnGateway (prioritize VPN Gateway)."
  }

  # Validate hub address prefix if provided
  validation {
    condition = alltrue([
      for config in values(var.regional_config) :
      config.hub_address_prefix == null || can(cidrhost(config.hub_address_prefix, 0))
    ])
    error_message = "Hub address prefix must be a valid CIDR notation if provided."
  }
}

# --- BGP-Specific Variables ---

variable "cato_bgp_asn" {
  description = "The BGP Autonomous System Number for the Cato side of the peering. Must not conflict with Azure vWAN's fixed ASN 65515."
  type        = number

  validation {
    condition     = var.cato_bgp_asn >= 64512 && var.cato_bgp_asn <= 65534 && var.cato_bgp_asn != 65515
    error_message = "Cato BGP ASN must be within the 16-bit private AS range (64512-65534) and cannot be 65515 (reserved for Azure vWAN hubs)."
  }
}

# NOTE: Secondary BGP peer is now always created for redundancy best practices

variable "cato_bgp_peer_config" {
  description = "Configuration for the BGP peers."
  type = map(object({
    metric                   = number
    default_action           = string
    advertise_all_routes     = bool
    advertise_default_route  = bool
    advertise_summary_routes = bool
    bfd_enabled              = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for config in values(var.cato_bgp_peer_config) :
      config.metric >= 1 && config.metric <= 65535
    ])
    error_message = "BGP peer metric must be a 16-bit value between 1 and 65535."
  }

  validation {
    condition = alltrue([
      for config in values(var.cato_bgp_peer_config) :
      contains(["ACCEPT", "DENY"], config.default_action)
    ])
    error_message = "BGP peer default_action must be either 'ACCEPT' or 'DENY'."
  }
  default = {
    primary = {
      metric                   = 100
      default_action           = "ACCEPT"
      advertise_all_routes     = true
      advertise_default_route  = true
      advertise_summary_routes = false
      bfd_enabled              = false
    },
    secondary = {
      metric                   = 200
      default_action           = "ACCEPT"
      advertise_all_routes     = true
      advertise_default_route  = true
      advertise_summary_routes = false
      bfd_enabled              = false
    }
  }
}