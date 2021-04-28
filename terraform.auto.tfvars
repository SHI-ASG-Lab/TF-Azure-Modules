RG_name            = "LAB-TFTEST-Fortinet"
RG_Env_Tag         = "DEV"
RG_SP_Name         = "LAB"

NSG_name           = "SecurityGroup1"

VNET_name          = "VirtualNetwork1"

mgmt_Subnet1_name  = "mgmtSubnet"
int_Subnet2_name   = "internalSubnet"
ext_Subnet3_name   = "externalSubnet"

# Select true for the FW vendor of choice. 
# Defaults are false, only one needs to be passed as true from front-end.
# These are string inputs, and will be converted to lowercase + boolean in main.tf.

Fortinet           = "TRUE"
Sophos             = "false"
Cisco              = "false"
Juniper            = "false"
PaloAlto           = "false"
Watchguard         = "false"

