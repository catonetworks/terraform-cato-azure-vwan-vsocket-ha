# To allow mac address to be retrieved
resource "time_sleep" "sleep_5_seconds" {
  for_each = var.regional_config

  create_duration = "30s"
  depends_on      = [azurerm_linux_virtual_machine.vsocket_primary]
}


# Time delay to allow for vsockets to upgrade and connect
resource "null_resource" "delay-600" {
  for_each = var.regional_config

  depends_on = [azurerm_virtual_machine_extension.vsocket-custom-script-primary]
  provisioner "local-exec" {
    command = "sleep 600"
  }
}

#################################################################################
# Add secondary socket to site via API until socket_site resrouce is updated to natively support
resource "null_resource" "configure_secondary_azure_vsocket" {
  for_each = var.regional_config

  depends_on = [
    null_resource.delay-600,
    azurerm_network_interface.lan-nic-secondary
  ]

  provisioner "local-exec" {
    command = <<EOF
      echo "[${each.key}] Adding secondary socket to site ${cato_socket_site.azure-site[each.key].id} with interface IP ${azurerm_network_interface.lan-nic-secondary[each.key].private_ip_address} and floating IP ${each.value.floating_ip}"
      
      # Execute the GraphQL mutation to add secondary socket
      response=$(curl -k -X POST \
        -H "Accept: application/json" \
        -H "Content-Type: application/json" \
        -H "x-API-Key: ${var.cato_token}" \
        "${var.baseurl}" \
        --data '{
          "query": "mutation siteAddSecondaryAzureVSocket($accountId: ID!, $addSecondaryAzureVSocketInput: AddSecondaryAzureVSocketInput!) { site(accountId: $accountId) { addSecondaryAzureVSocket(input: $addSecondaryAzureVSocketInput) { id } } }",
          "variables": {
            "accountId": "${var.cato_account_id}",
            "addSecondaryAzureVSocketInput": {
              "floatingIp": "${each.value.floating_ip}",
              "interfaceIp": "${azurerm_network_interface.lan-nic-secondary[each.key].private_ip_address}",
              "site": {
                "by": "ID",
                "input": "${cato_socket_site.azure-site[each.key].id}"
              }
            }
          },
          "operationName": "siteAddSecondaryAzureVSocket"
        }' )
      
      echo "[${each.key}] API Response: $response"
      
      # Check for errors in the response
      if echo "$response" | grep -q "error"; then
        echo "[${each.key}] ERROR: API call failed with response: $response"
        exit 1
      else
        echo "[${each.key}] Secondary socket API call completed successfully"
      fi
    EOF
  }

  triggers = {
    account_id = var.cato_account_id
    site_id    = cato_socket_site.azure-site[each.key].id
    region     = each.key
  }
}

# Sleep to allow Secondary vSocket serial retrieval
resource "null_resource" "sleep_30_seconds" {
  for_each = var.regional_config

  provisioner "local-exec" {
    command = "echo 'Waiting 60 seconds for secondary socket to be registered in Cato account snapshot...'; sleep 60"
  }
  depends_on = [null_resource.configure_secondary_azure_vsocket]
}

# To allow mac address to be retrieved
resource "time_sleep" "sleep_5_seconds_secondary" {
  for_each = var.regional_config

  create_duration = "30s"
  depends_on      = [azurerm_linux_virtual_machine.vsocket_secondary]
}

# Create HA Settings Secondary
resource "null_resource" "run_command_ha_primary" {
  for_each = var.regional_config

  provisioner "local-exec" {
    command = <<EOT
      az vm run-command invoke \
        --resource-group ${local.rg_name} \
        --name "${each.value.site_name}-vSocket-Primary" \
        --command-id RunShellScript \
        --scripts "echo '{\"location\": \"${each.value.location}\", \"subscription_id\": \"${var.azure_subscription_id}\", \"vnet\": \"${azurerm_virtual_network.vnet[each.key].name}\", \"group\": \"${local.rg_name}\", \"vnet_group\": \"${local.rg_name}\", \"subnet\": \"${azurerm_subnet.subnet-lan[each.key].name}\", \"nic\": \"${azurerm_network_interface.lan-nic-primary[each.key].name}\", \"ha_nic\": \"${azurerm_network_interface.lan-nic-secondary[each.key].name}\", \"lan_nic_ip\": \"${azurerm_network_interface.lan-nic-primary[each.key].private_ip_address}\", \"lan_nic_mac\": \"${data.azurerm_network_interface.lan-mac-primary[each.key].mac_address}\", \"subnet_cidr\": \"${each.value.subnet_range_lan}\", \"az_mgmt_url\": \"management.azure.com\"}' > /cato/socket/configuration/vm_config.json"
    EOT
  }

  depends_on = [
    azurerm_virtual_machine_extension.vsocket-custom-script-secondary,
    data.azurerm_network_interface.lan-mac-primary
  ]
}

resource "null_resource" "run_command_ha_secondary" {
  for_each = var.regional_config

  provisioner "local-exec" {
    command = <<EOT
      az vm run-command invoke \
        --resource-group ${local.rg_name} \
        --name "${each.value.site_name}-vSocket-Secondary" \
        --command-id RunShellScript \
        --scripts "echo '{\"location\": \"${each.value.location}\", \"subscription_id\": \"${var.azure_subscription_id}\", \"vnet\": \"${azurerm_virtual_network.vnet[each.key].name}\", \"group\": \"${local.rg_name}\", \"vnet_group\": \"${local.rg_name}\", \"subnet\": \"${azurerm_subnet.subnet-lan[each.key].name}\", \"nic\": \"${azurerm_network_interface.lan-nic-secondary[each.key].name}\", \"ha_nic\": \"${azurerm_network_interface.lan-nic-primary[each.key].name}\", \"lan_nic_ip\": \"${azurerm_network_interface.lan-nic-secondary[each.key].private_ip_address}\", \"lan_nic_mac\": \"${data.azurerm_network_interface.lan-mac-secondary[each.key].mac_address}\", \"subnet_cidr\": \"${each.value.subnet_range_lan}\", \"az_mgmt_url\": \"management.azure.com\"}' > /cato/socket/configuration/vm_config.json"
    EOT
  }

  depends_on = [
    azurerm_virtual_machine_extension.vsocket-custom-script-secondary,
    data.azurerm_network_interface.lan-mac-secondary
  ]
}

# Time delay to allow for vsockets to upgrade
resource "null_resource" "delay" {
  for_each = var.regional_config

  depends_on = [null_resource.run_command_ha_secondary]
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

# Reboot both vsockets
resource "null_resource" "reboot_vsocket_primary" {
  for_each = var.regional_config

  provisioner "local-exec" {
    command = <<EOT
      az vm restart --resource-group "${local.rg_name}" --name "${each.value.site_name}-vSocket-Primary"
    EOT
  }

  depends_on = [
    null_resource.run_command_ha_secondary
  ]
}

resource "null_resource" "reboot_vsocket_secondary" {
  for_each = var.regional_config

  provisioner "local-exec" {
    command = <<EOT
      az vm restart --resource-group "${local.rg_name}" --name "${each.value.site_name}-vSocket-Secondary"
    EOT
  }

  depends_on = [
    null_resource.run_command_ha_secondary
  ]
}

# Allow vSocket to be disconnected to delete site
resource "null_resource" "sleep_before_delete" {
  for_each = var.regional_config

  provisioner "local-exec" {
    when    = destroy
    command = "sleep 10"
  }
}
