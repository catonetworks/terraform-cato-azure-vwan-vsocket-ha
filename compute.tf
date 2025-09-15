# Data sources to read current MAC addresses after VM creation
data "azurerm_network_interface" "wan-mac-primary" {
  for_each = var.regional_config

  name                = azurerm_network_interface.wan-nic-primary[each.key].name
  resource_group_name = local.rg_name
  depends_on          = [time_sleep.sleep_5_seconds]
}

data "azurerm_network_interface" "lan-mac-primary" {
  for_each = var.regional_config

  name                = azurerm_network_interface.lan-nic-primary[each.key].name
  resource_group_name = local.rg_name
  depends_on          = [time_sleep.sleep_5_seconds]
}

data "azurerm_network_interface" "wan-mac-secondary" {
  for_each = var.regional_config

  name                = azurerm_network_interface.wan-nic-secondary[each.key].name
  resource_group_name = local.rg_name
  depends_on          = [time_sleep.sleep_5_seconds_secondary]
}

data "azurerm_network_interface" "lan-mac-secondary" {
  for_each = var.regional_config

  name                = azurerm_network_interface.lan-nic-secondary[each.key].name
  resource_group_name = local.rg_name
  depends_on          = [time_sleep.sleep_5_seconds_secondary]
}

# Create Primary Vsocket Virtual Machine
resource "azurerm_linux_virtual_machine" "vsocket_primary" {
  for_each = var.regional_config

  location            = each.value.location
  name                = "${each.value.site_name}-vSocket-Primary"
  computer_name       = replace("${each.value.site_name}-vSocket-Primary", "/[\\\\/\\[\\]:|<>+=;,?*@&~!#$%^()_{}' ]/", "-")
  resource_group_name = local.rg_name
  size                = each.value.vm_size
  network_interface_ids = [
    azurerm_network_interface.mgmt-nic-primary[each.key].id,
    azurerm_network_interface.wan-nic-primary[each.key].id,
    azurerm_network_interface.lan-nic-primary[each.key].id
  ]
  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true
  admin_username                  = random_string.vsocket-random-username[each.key].result
  admin_password                  = "${random_string.vsocket-random-password[each.key].result}@"

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = "" # Empty string enables boot diagnostics
  }

  # Assign CatoHaIdentity to the Vsocket
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.CatoHaIdentity[each.key].id]
  }

  # OS disk configuration from image
  os_disk {
    name                 = "${each.value.site_name}-vSocket-disk-primary"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 8
  }

  plan {
    name      = "public-cato-socket"
    publisher = "catonetworks"
    product   = "cato_socket"
  }

  source_image_reference {
    publisher = "catonetworks"
    offer     = "cato_socket"
    sku       = "public-cato-socket"
    version   = "23.0.19605"
  }

  depends_on = [
    data.cato_accountSnapshotSite.azure-site-2
  ]
  tags = merge(var.tags, { region = each.key })
}


resource "azurerm_virtual_machine_extension" "vsocket-custom-script-primary" {
  for_each = var.regional_config

  auto_upgrade_minor_version = true
  name                       = "vsocket-custom-script-primary"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_linux_virtual_machine.vsocket_primary[each.key].id
  lifecycle {
    ignore_changes = all
  }
  settings = <<SETTINGS
  {
  "commandToExecute": "echo '{\"wan_ip\" : \"${azurerm_network_interface.wan-nic-primary[each.key].private_ip_address}\", \"wan_name\" : \"${azurerm_network_interface.wan-nic-primary[each.key].name}\", \"wan_nic_mac\" : \"${lower(replace(data.azurerm_network_interface.wan-mac-primary[each.key].mac_address, "-", ":"))}\", \"lan_ip\" : \"${azurerm_network_interface.lan-nic-primary[each.key].private_ip_address}\", \"lan_name\" : \"${azurerm_network_interface.lan-nic-primary[each.key].name}\", \"lan_nic_mac\" : \"${lower(replace(data.azurerm_network_interface.lan-mac-primary[each.key].mac_address, "-", ":"))}\"}' > /cato/nics_config.json; echo '${local.primary_serial[each.key][0]}' > /cato/serial.txt;${join(";", each.value.commands)}"
  }
SETTINGS
  depends_on = [
    azurerm_linux_virtual_machine.vsocket_primary,
    azurerm_network_interface.mgmt-nic-primary,
    azurerm_network_interface.wan-nic-primary,
    azurerm_network_interface.lan-nic-primary,
    time_sleep.sleep_5_seconds,
    data.azurerm_network_interface.wan-mac-primary,
    data.azurerm_network_interface.lan-mac-primary,
  ]
}


resource "azurerm_linux_virtual_machine" "vsocket_secondary" {
  for_each = var.regional_config

  location            = each.value.location
  name                = "${each.value.site_name}-vSocket-Secondary"
  computer_name       = replace("${each.value.site_name}-vSocket-Secondary", "/[\\\\/\\[\\]:|<>+=;,?*@&~!#$%^()_{}' ]/", "-")
  resource_group_name = local.rg_name
  size                = each.value.vm_size
  network_interface_ids = [
    azurerm_network_interface.mgmt-nic-secondary[each.key].id,
    azurerm_network_interface.wan-nic-secondary[each.key].id,
    azurerm_network_interface.lan-nic-secondary[each.key].id
  ]
  disable_password_authentication = false
  provision_vm_agent              = true
  allow_extension_operations      = true
  admin_username                  = random_string.vsocket-random-username[each.key].result
  admin_password                  = "${random_string.vsocket-random-password[each.key].result}@"

  # Boot diagnostics
  boot_diagnostics {
    storage_account_uri = "" # Empty string enables boot diagnostics
  }

  # Assign CatoHaIdentity to the Vsocket
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.CatoHaIdentity[each.key].id]
  }

  # OS disk configuration from image
  os_disk {
    name                 = "${each.value.site_name}-vSocket-disk-secondary"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 8
  }

  plan {
    name      = "public-cato-socket"
    publisher = "catonetworks"
    product   = "cato_socket"
  }

  source_image_reference {
    publisher = "catonetworks"
    offer     = "cato_socket"
    sku       = "public-cato-socket"
    version   = "23.0.19605"
  }

  depends_on = [
    data.cato_accountSnapshotSite.azure-site-secondary
  ]
  tags = merge(var.tags, { region = each.key })
}


resource "azurerm_virtual_machine_extension" "vsocket-custom-script-secondary" {
  for_each = var.regional_config

  auto_upgrade_minor_version = true
  name                       = "vsocket-custom-script-secondary"
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  virtual_machine_id         = azurerm_linux_virtual_machine.vsocket_secondary[each.key].id
  lifecycle {
    ignore_changes = all
  }

  settings = <<SETTINGS
  {
  "commandToExecute": "echo '{\"wan_ip\" : \"${azurerm_network_interface.wan-nic-secondary[each.key].private_ip_address}\", \"wan_name\" : \"${azurerm_network_interface.wan-nic-secondary[each.key].name}\", \"wan_nic_mac\" : \"${lower(replace(data.azurerm_network_interface.wan-mac-secondary[each.key].mac_address, "-", ":"))}\", \"lan_ip\" : \"${azurerm_network_interface.lan-nic-secondary[each.key].private_ip_address}\", \"lan_name\" : \"${azurerm_network_interface.lan-nic-secondary[each.key].name}\", \"lan_nic_mac\" : \"${lower(replace(data.azurerm_network_interface.lan-mac-secondary[each.key].mac_address, "-", ":"))}\"}' > /cato/nics_config.json; echo '${local.secondary_serial[each.key][0]}' > /cato/serial.txt;${join(";", each.value.commands)}"
  }
  SETTINGS
  depends_on = [
    azurerm_linux_virtual_machine.vsocket_secondary,
    azurerm_network_interface.mgmt-nic-secondary,
    azurerm_network_interface.wan-nic-secondary,
    azurerm_network_interface.lan-nic-secondary,
    time_sleep.sleep_5_seconds_secondary,
    data.azurerm_network_interface.wan-mac-secondary,
    data.azurerm_network_interface.lan-mac-secondary,
  ]
}
