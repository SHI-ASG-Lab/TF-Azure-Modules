
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

# Create Managed Disk from Snapshot

resource "azurerm_managed_disk" "osdisk1" {
  name                 = "${var.w10vmName}_osdisk"
  location             = var.RGlocation
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = var.w10snapshot
  disk_size_gb         = "132"

  tags = var.tags
}
# Create VM, attach OS Disk, attach Nic(s), associate with vNet

resource "azurerm_virtual_machine" "W10" {
  name                  = var.w10vmName
  location              = var.RGlocation
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.W10-intNic.id]
  primary_network_interface_id = "azurerm_network_interface.${var.w10vmName}-intNic.id"
  vm_size               = "Standard_D4s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_os_disk {
    name              = azurerm_managed_disk.osdisk1.name
    os_type           = "windows"
    create_option     = "Attach"
    managed_disk_id   = azurerm_managed_disk.osdisk1.id
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