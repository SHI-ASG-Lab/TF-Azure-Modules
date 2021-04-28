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
locals {
  Fortinet = tobool(lower(var.Fortinet))
  Sophos = tobool(lower(var.Sophos))
  Cisco = tobool(lower(var.Cisco))
  Juniper = tobool(lower(var.Juniper))
  PaloAlto = tobool(lower(var.PaloAlto))
  Watchguard = tobool(lower(var.Watchguard))

  common_tags = {
    Owner = "JIsley"
    Requestor = "?"
    Environment = var.RG_Env_Tag
    SP = var.RG_SP_Name
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
###
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
    source = "./FW/Fortinet.tf"
    count = local.Fortinet ? 1 : 0 

    resource_group_name = azurerm_resource_group.main.name
    RGlocation = azurerm_resource_group.main.location

    mgmt_subnet_id     = azurerm_subnet.mgmtsubnet.id
    int_subnet_id      = azurerm_subnet.intsubnet.id
    ext_subnet_id      = azurerm_subnet.extsubnet.id 

    tags = local.common_tags
}

module "Sophos" {
    source = "../FW/Sophos.tf"
    count = local.Sophos ? 1 : 0
}

module "Cisco" {
    source = "../FW/CiscoFTD.tf"
    count = local.Cisco ? 1 : 0
}

module "Juniper" {
    source = "../FW/Juniper.tf"
    count = var.Juniper ? 1 : 0
}

module "PaloAlto" {
    source = "../FW/PaloAlto.tf"
    count = var.PaloAlto ? 1 : 0
}

module "Watchguard" {
    source = "../FW/Watchguard.tf"
    count = var.Watchguard ? 1 : 0
}

