# Create the NICs and assign to subnets

resource "azurerm_network_interface" "EDRIntNic1" {
  name = "EDRinternal-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "internal"
    subnet_id = var.int_subnet_id
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "dynamic"
    primary = true

  }
}

# Create Managed Disk from Snapshots

resource "azurerm_managed_disk" "osdisk1" {
  name                 = "EDRUbuntu_osdisk"
  location             = var.RGlocation
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = var.source_resource_id
  disk_size_gb         = "32"

  tags = var.tags
}

# Create VM, attach OS Disk, attach Nic(s), associate with vNet

resource "azurerm_virtual_machine" "EDR" {
  name                  = "EDR-Ubuntu1"
  location              = var.RGlocation
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.EDRIntNic1.id]
  primary_network_interface_id = azurerm_network_interface.EDRIntNic1.id
  vm_size               = "Standard_D2s_v3"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_os_disk {
    name              = azurerm_managed_disk.osdisk1.name
    os_type           = "linux"
    create_option     = "Attach"
    managed_disk_id   = azurerm_managed_disk.osdisk1.id
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags     = var.tags
}

# Configure Auto-Shutdown for the VM for each night at 10pm CST.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "AutoShutdown1" {
  virtual_machine_id = azurerm_virtual_machine.EDR.id
  location           = var.RGlocation
  enabled            = true
  daily_recurrence_time = "2200"
  timezone              = "Central Standard Time"

  notification_settings {
    enabled         = false
  }
}