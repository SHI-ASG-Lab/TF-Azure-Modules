
# Create the NICs and assign to subnets

resource "azurerm_network_interface" "W10-intNic" {
  name = "${var.w10vmName}-internal-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "internal"
    subnet_id = var.int_subnet_id
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "static"
    private_ip_address = "10.0.2.${var.ipnum}"
    primary = true
  }
}

# Accept Marketplace agreement for W10 system
resource "azurerm_marketplace_agreement" "W10" {
  publisher = "MicrosoftWindowsDesktop"
  offer     = "Windows-10"
  plan      = "20h2-pro"
}

# Create VM, attach OS Disk, attach Nic(s), associate with vNet

resource "azurerm_virtual_machine" "W10" {
  name                  = var.w10vmName
  location              = var.RGlocation
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.W10-intNic.id]
  primary_network_interface_id = "azurerm_network_interface.${var.w10vmName}-intNic.id"
  vm_size               = "Standard_E2s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  plan {
    name = "20h2-pro"
    publisher = "MicrosoftWindowsDesktop"
    product = "Windows-10"
  }
  storage_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "20h2-pro"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.w10vmName}-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "StandardSSD_LRS"
    os_type           = "Windows"
  }
  os_profile {
    computer_name  = "W10"
    admin_username = "shi"
    admin_password = "5ecur!ty_10I"
  }
  os_profile_windows_config {
  }
  tags     = var.tags
}

# Configure Auto-Shutdown for the VM for each night at 10pm CST.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "AutoShutdown1" {
  virtual_machine_id = azurerm_virtual_machine.W10.id
  location           = var.RGlocation
  enabled            = true
  daily_recurrence_time = "2200"
  timezone              = "Central Standard Time"

  notification_settings {
    enabled         = false
  }
}