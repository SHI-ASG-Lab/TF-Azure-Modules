# Create a public IP for the system to use
resource "azurerm_public_ip" "azPubIp" {
  name = "Terapackets-PubIp1"
  resource_group_name = var.resource_group_name
  location = var.RGlocation
  allocation_method = "Static"
}

# Create the NICs and assign to subnets
resource "azurerm_network_interface" "Nic1" {
  name = "Terapackets-mgmt-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "mgmt"
    subnet_id = var.mgmt_subnet_id
    primary = true
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.1.5"
    public_ip_address_id = azurerm_public_ip.azPubIp.id

  }
}

resource "azurerm_network_interface" "Nic2" {
  name = "Terapackets-internal-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "internal"
    subnet_id = var.int_subnet_id
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.2.5"
    primary = false

  }
}

resource "azurerm_network_interface" "Nic3" {
  name = "Terapackets-external-nic"
  resource_group_name = var.resource_group_name
  location = var.RGlocation

  ip_configuration {
    name = "external"
    subnet_id = var.ext_subnet_id
    private_ip_address_version = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address = "10.0.3.5"
    primary = false
  }
}

# Create Managed Disk from Snapshot

resource "azurerm_managed_disk" "osdisk1" {
  name                 = "Terapackets_osdisk"
  location             = var.RGlocation
  resource_group_name  = var.resource_group_name
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = var.source_resource_id
  disk_size_gb         = "32"

  tags = var.tags
}


# Create VM, attach OS Disk, attach Nic(s), associate with vNet

resource "azurerm_virtual_machine" "Terapackets" {
  name                  = "Terapackets"
  location              = var.RGlocation
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.Nic1.id, azurerm_network_interface.Nic2.id, azurerm_network_interface.Nic3.id]
  primary_network_interface_id = azurerm_network_interface.Nic1.id
  vm_size               = "Standard_E8s_v4"

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
  #boot_diagnostics {
  #  enabled          = true
  #  storage_uri      = "/subscriptions/5ac94ae0-f68d-42bf-bcce-8ed2fd7cebb9/resourceGroups/cloud-shell-storage-southcentralus/providers/Microsoft.Storage/storageAccounts/cs71003200107c1f0e0/blobServices/default"
  #}
  tags     = var.tags
}

# Configure Auto-Shutdown for the VM for each night at 10pm CST.
resource "azurerm_dev_test_global_vm_shutdown_schedule" "AutoShutdown1" {
  virtual_machine_id = azurerm_virtual_machine.Terapackets.id
  location           = var.RGlocation
  enabled            = true
  daily_recurrence_time = "2200"
  timezone              = "Central Standard Time"

  notification_settings {
    enabled         = false
  }
}