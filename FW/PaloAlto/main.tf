# Create a public IP for the system to use
resource "azurerm_public_ip" "azPubIp" {
  name = "azPubIp1"
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
    subnet_id = azurerm_subnet.mgmtsubnet.id
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
    subnet_id = azurerm_subnet.intsubnet.id
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
    subnet_id = azurerm_subnet.extsubnet.id
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.3.4"
    primary = false
  }
}

# PaloAlto FW
resource "azurerm_virtual_machine" "PaloAltoFW" {
  name                          = PAN_FW
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  network_interface_ids         = [azurerm_network_interface.Nic1.id, azurerm_network_interface.Nic2.id, azurerm_network_interface.Nic3.id]
  primary_network_interface_id  = azurerm_network_interface.Nic1.id
  vm_size                       = "Standard_E8s_v4"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  plan {
    name = "bundle2"
    publisher = "paloaltonetworks"
    product = "vmseries1"
  }
  storage_image_reference {
    publisher = "paloaltonetworks"
    offer     = "vmseries1"
    sku       = "bundle2"
    version   = "latest"
  }
  storage_os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
  os_profile {
    computer_name  = "PAN_FW"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = local.common_tags
}

# Configure Auto-Shutdown for the PAN VM for each night at 10pm CST.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "PANShutdown" {
  virtual_machine_id = azurerm_virtual_machine.PaloAltoFW.id
  location           = azurerm_resource_group.main.location
  enabled            = true
  daily_recurrence_time = "2200"
  timezone              = "Central Standard Time"

  notification_settings {
    enabled         = false
  }
  depends_on = [
    azurerm_virtual_machine.PaloAltoFW
  ]
}

# Output Public IP when finished
output "Azure_Public_IP" {
    value = azurerm_public_ip.azPubIp.ip_address
}
