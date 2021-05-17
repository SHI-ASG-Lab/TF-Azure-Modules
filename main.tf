# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.46.0"
    }
  }
}

provider "azurerm" {
  features {}
}


# Variable Declarations
variable "RG_name" {
  type = string
}

variable "RG_Env_Tag" {
    type = string
}

variable "RG_SP_Name" {
  type = string
}

variable "NSG_name" {
  type = string
}

variable "VNET_name" {
  type = string
}

variable "mgmt_Subnet1_name" {
  type = string
  default = "mgmtSubnet"
}

variable "int_Subnet2_name" {
  type = string
  default = "internalSubnet"
}

variable "ext_Subnet3_name" {
  type = string
  default = "externalSubnet"
}

variable "Fortinet" {
  type = string
  default = "false"
}
variable "Sophos" {
  type = string
  default = "false"
}
variable "Cisco" {
  type = string
  default = "false"
}
variable "Juniper" {
  type = string
  default = "false"
}
variable "PaloAlto" {
  type = string
  default = "false"
}
variable "Watchguard" {
  type = string
  default = "false"
}
variable "EDR" {
  type = string
  default = "false"
}
variable "w10" {
  type = number
  default = 0
}
variable "w10snap" {
  type = number
  default = 0
}
variable "Ubuntu" {
  type = number
  default = 0
}
variable "UbuntuVMsize" {
  type = string
  default = "Standard_E2s_v3"
}
variable "Win19DC" {
  type = number
  default = 0
}
variable "Terapackets" {
  type = string
  default = "false"
}

locals {
  Fortinet = tobool(lower(var.Fortinet))
  Sophos = tobool(lower(var.Sophos))
  Cisco = tobool(lower(var.Cisco))
  Juniper = tobool(lower(var.Juniper))
  PaloAlto = tobool(lower(var.PaloAlto))
  Watchguard = tobool(lower(var.Watchguard))

  EDR = tobool(lower(var.EDR))
  snapshotEDR_URL = "/subscriptions/5ac94ae0-f68d-42bf-bcce-8ed2fd7cebb9/resourceGroups/cloud-shell-storage-southcentralus/providers/Microsoft.Compute/snapshots/EDRDemoUbuntu_v1"

  snapshotW10_URL = "/subscriptions/5ac94ae0-f68d-42bf-bcce-8ed2fd7cebb9/resourceGroups/cloud-shell-storage-southcentralus/providers/Microsoft.Compute/snapshots/W10-1_Snap"

  Terapackets = tobool(lower(var.Terapackets))
  snapshotTP_URL = "/subscriptions/5ac94ae0-f68d-42bf-bcce-8ed2fd7cebb9/resourceGroups/cloud-shell-storage-southcentralus/providers/Microsoft.Compute/snapshots/TerapacketsSnap1"

  common_tags = {
    Owner       = "JIsley"
    Requestor   = "AMarkell"
    Environment = var.RG_Env_Tag
    SP          = var.RG_SP_Name
  }
}

resource "azurerm_resource_group" "main" {
  name     = var.RG_name
  location = "southcentralus"

  tags = local.common_tags
}

resource "azurerm_network_security_group" "NSG1" {
  name                = var.NSG_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "main" {
  name                = var.VNET_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Create subnets within the virtual network
resource "azurerm_subnet" "mgmtsubnet" {
    name           = var.mgmt_Subnet1_name
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "intsubnet" {
    name           = var.int_Subnet2_name
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "extsubnet" {
    name           = var.ext_Subnet3_name
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.3.0/24"]
}
# 4TH SUBNET FOR CISCO
resource "azurerm_subnet" "diagsubnet" {
    count = local.Cisco ? 1 : 0
    name           = "DiagSubnet"
    resource_group_name = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes = ["10.0.4.0/24"]
}

# Associate Subnets with NSG
resource "azurerm_subnet_network_security_group_association" "mgmtSubAssocNsg" {
  subnet_id                 = azurerm_subnet.mgmtsubnet.id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}

resource "azurerm_subnet_network_security_group_association" "intSubAssocNsg" {
  subnet_id                 = azurerm_subnet.intsubnet.id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}

resource "azurerm_subnet_network_security_group_association" "extSubAssocNsg" {
  subnet_id                 = azurerm_subnet.extsubnet.id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}
# 4TH SUBNET FOR CISCO
resource "azurerm_subnet_network_security_group_association" "diagSubAssocNsg" {
  count = local.Cisco ? 1 : 0
  subnet_id                 = azurerm_subnet.diagsubnet[0].id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}

# Create Route Tables and specify routes
resource "azurerm_route_table" "mgmtRtable" {
  #count = signum(local.Fortinet + local.Sophos + local.Cisco + local.Juniper + local.PaloAlto + local.Watchguard)
  name                          = "mgmtRouteTable"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = true

  route {
    name           = "mgmt2internal"
    address_prefix = "10.0.2.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }
  route {
    name           = "mgmt2ext"
    address_prefix = "10.0.3.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.3.4"
  }
}

resource "azurerm_route_table" "intRtable" {
  #count = signum(local.Fortinet + local.Sophos + local.Cisco + local.Juniper + local.PaloAlto + local.Watchguard)
  name                          = "intRouteTable"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = true

  route {
    name           = "int2mgmt"
    address_prefix = "10.0.1.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }
  route {
    name           = "int2ext"
    address_prefix = "10.0.3.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.3.4"
  }
}

resource "azurerm_route_table" "extRtable" {
  #count = signum(local.Fortinet + local.Sophos + local.Cisco + local.Juniper + local.PaloAlto + local.Watchguard)
  name                          = "extRouteTable"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = true

  route {
    name           = "ext2internal"
    address_prefix = "10.0.2.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.2.4"
  }
  route {
    name           = "ext2mgmt"
    address_prefix = "10.0.1.0/24"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "10.0.1.4"
  }
}

# Associate Route Tables with Subnets
resource "azurerm_subnet_route_table_association" "mgmtassoc" {
  subnet_id      = azurerm_subnet.mgmtsubnet.id
  route_table_id = azurerm_route_table.mgmtRtable.id
}
resource "azurerm_subnet_route_table_association" "intassoc" {
  subnet_id      = azurerm_subnet.intsubnet.id
  route_table_id = azurerm_route_table.intRtable.id
}
resource "azurerm_subnet_route_table_association" "extassoc" {
  subnet_id      = azurerm_subnet.extsubnet.id
  route_table_id = azurerm_route_table.extRtable.id
}

# Create NGFW VM with objects defined Above. 
# ANY ngfw from below (and it's auto-shutdown-schedule) marked as "true" in the variables 
# will be produced in the TF Plan.

module "Fortinet" {
    source = "./modules/FW/Fortinet"
    count = local.Fortinet ? 1 : 0 

    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location

    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 

    tags = local.common_tags
}

module "Sophos" {
    source = "./modules/FW/Sophos"
    count = local.Sophos ? 1 : 0

    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location

    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 

    tags = local.common_tags
}

module "Cisco" {
    source = "./modules/FW/CiscoFTD"
    count = local.Cisco ? 1 : 0
    
    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location

    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 
    diag_subnet_id     = azurerm_subnet.diagsubnet[0].id

    tags = local.common_tags
}

module "Juniper" {
    source = "./modules/FW/Juniper"
    count = local.Juniper ? 1 : 0
    
    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location

    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 

    tags = local.common_tags
}

module "PaloAlto" {
    source = "./modules/FW/PaloAlto"
    count = local.PaloAlto ? 1 : 0
    
    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location

    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 

    tags = local.common_tags
}

module "Watchguard" {
    source = "./modules/FW/Watchguard"
    count = local.Watchguard ? 1 : 0
    
    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location

    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 

    tags = local.common_tags
}

# Add in EDR Ubuntu system if desired

module "EDRubuntu" {
  source = "./modules/Servers/EDRubuntu"
  count = local.EDR ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
  int_subnet_id      = azurerm_subnet.intsubnet.id
  ext_subnet_id      = azurerm_subnet.extsubnet.id 

  tags = local.common_tags

  source_resource_id   = local.snapshotEDR_URL
}

# Add any number of Ubuntu servers
module "Ubuntu" {
  source = "./modules/Servers/Ubuntu"
  count = var.Ubuntu

  UbuntuVmName = "Ubuntu-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
  int_subnet_id      = azurerm_subnet.intsubnet.id
  ext_subnet_id      = azurerm_subnet.extsubnet.id 

  ipnum = count.index + 20
  UbuntuVMsize = var.UbuntuVMsize

  tags = local.common_tags

}

# Add in any number of Endpoint Win10 systems from Marketplace as desired
module "Win10" {
  source = "./modules/Endpoint/Win10"
  count = var.w10

  w10vmName = "W10-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
  int_subnet_id      = azurerm_subnet.intsubnet.id
  ext_subnet_id      = azurerm_subnet.extsubnet.id 

  tags = local.common_tags

  ipnum = count.index + 10
  
}

# Add in any number of Endpoint Win10 systems from snapshot as desired
module "Win10snap" {
  source = "./modules/Endpoint/Win10Snap"
  count = var.w10snap

  w10vmName = "W10-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
  int_subnet_id      = azurerm_subnet.intsubnet.id
  ext_subnet_id      = azurerm_subnet.extsubnet.id 
  w10snapshot        = local.snapshotW10_URL
  tags = local.common_tags

  ipnum = count.index + 15
  
}

# Add in any number of "Windows 2019 Datacenter" Servers
module "Windows2019DC" {
  source = "./modules/Servers/Windows2019DC"
  count = var.Win19DC

  VmName = "Win19-${count.index}"
  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
  int_subnet_id      = azurerm_subnet.intsubnet.id
  ext_subnet_id      = azurerm_subnet.extsubnet.id 
  tags = local.common_tags

  ipnum = count.index + 30
  
}

# Add a Terapackets Server
module "Terapackets" {
  source = "./modules/Servers/Terapackets"
  count = local.Terapackets ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  RGlocation = azurerm_resource_group.main.location

  mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
  int_subnet_id      = azurerm_subnet.intsubnet.id
  ext_subnet_id      = azurerm_subnet.extsubnet.id 

  tags = local.common_tags

  source_resource_id   = local.snapshotTP_URL
}