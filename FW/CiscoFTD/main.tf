# Create a public IP for the system to use
resource "azurerm_public_ip" "azPubIp" {
  name = "azPubIp1"
  resource_group_name = var.resource_group_name
  location = var.RGlocation
  allocation_method = "Static"
}
# 2ND PUB IP FOR CISCO SETUP
resource "azurerm_public_ip" "azPubIp2" {
  name = "azPubIp2"
  resource_group_name = var.resource_group_name
  location = var.RGlocation
  allocation_method = "Static"
}


# Create the NICs and assign to subnets
resource "azurerm_network_interface" "Nic1" {
  name = "mgmt-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "mgmt"
    subnet_id = var.mgmt_subnet_id
    primary = true
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.1.4"
    public_ip_address_id = azurerm_public_ip.azPubIp.id

  }
}

resource "azurerm_network_interface" "Nic2" {
  name = "internal-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "internal"
    subnet_id = var.int_subnet_id
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.2.4"
    primary = false

  }
}

resource "azurerm_network_interface" "Nic3" {
  name = "external-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "external"
    subnet_id = var.ext_subnet_id
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.3.4"
    primary = false
  }
}

# 4TH DIAG NIC FOR CISCO
resource "azurerm_network_interface" "Nic4" {
  name = "diag-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "Diag"
    subnet_id = var.diag_subnet_id
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.4.4"
    primary = false

  }
}

# CiscoFTD FW
resource "azurerm_virtual_machine" "CiscoFTD" {
  name                          = "CiscoFTD"
  resource_group_name           = var.resource_group_name
  location                      = var.RGlocation
  network_interface_ids         = [azurerm_network_interface.Nic1.id, azurerm_network_interface.Nic2.id, azurerm_network_interface.Nic3.id, azurerm_network_interface.Nic4[0].id]
  primary_network_interface_id  = azurerm_network_interface.Nic1.id
  vm_size                       = "Standard_D3_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  plan {
    name = "ftdv-azure-byol"
    publisher = "cisco"
    product = "cisco-ftdv"
  }
  storage_image_reference {
    publisher = "cisco"
    offer     = "cisco-ftdv"
    sku       = "ftdv-azure-byol"
    version   = "latest"
  }
  storage_os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
  os_profile {
    computer_name  = "CiscoFTD"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags
}

# Configure Auto-Shutdown for the Cisco VM for each night at 10pm CST.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "CiscoShutdown" {
  virtual_machine_id = azurerm_virtual_machine.CiscoFTD.id
  location           = var.RGlocation
  enabled            = true
  daily_recurrence_time = "2200"
  timezone              = "Central Standard Time"

  notification_settings {
    enabled         = false
  }
  depends_on = [
    azurerm_virtual_machine.CiscoFTD
  ]
}

# Output Public IP when finished
output "Azure_Public_IP" {
    value = azurerm_public_ip.azPubIp.ip_address
}
output "Azure_Public_IP2" {
    value = azurerm_public_ip.azPubIp2.ip_address
}