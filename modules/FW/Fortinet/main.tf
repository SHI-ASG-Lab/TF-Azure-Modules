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

# Fortinet FW
resource "azurerm_virtual_machine" "FortinetFW" {
  name                          = "FortigateFW"
  resource_group_name           = var.resource_group_name
  location                      = var.RGlocation
  network_interface_ids         = [azurerm_network_interface.Nic1.id, azurerm_network_interface.Nic2.id, azurerm_network_interface.Nic3.id]
  primary_network_interface_id  = azurerm_network_interface.Nic1.id
  vm_size                       = "Standard_E8s_v4"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  plan {
    name = "fortinet_fg-vm_payg_20190624"
    publisher = "fortinet"
    product = "fortinet_fortigate-vm_v5"
  }
  storage_image_reference {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku       = "fortinet_fg-vm_payg_20190624"
    version   = "latest"
  }
  storage_os_disk {
    name              = "osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
  }
  os_profile {
    computer_name  = "FortigateFW"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags
}

# Configure Auto-Shutdown for the Fortinet VM for each night at 10pm CST.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "FortinetShutdown" {
  virtual_machine_id = azurerm_virtual_machine.FortinetFW.id
  location           = var.RGlocation
  enabled            = true
  daily_recurrence_time = "2200"
  timezone              = "Central Standard Time"

  notification_settings {
    enabled         = false
  }
  depends_on = [
    azurerm_virtual_machine.FortinetFW
  ]
}

# Output Public IP when finished
output "Azure_Public_IP" {
    value = azurerm_public_ip.azPubIp.ip_address
}
