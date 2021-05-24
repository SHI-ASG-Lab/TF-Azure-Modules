RG_name            = "Lab-MorpheusMade-TF2"
RG_Env_Tag         = "Dev"
RG_SP_Name         = "Lab"

NSG_name           = "SecurityGroup1"

VNET_name          = "VirtualNetwork1"

mgmt_Subnet1_name  = "mgmtSubnet"
int_Subnet2_name   = "internalSubnet"
ext_Subnet3_name   = "externalSubnet"

# Select true for the FW vendor of choice. 
# Defaults are false, only one needs to be passed as true from front-end.
# These are string inputs, and will be converted to lowercase + boolean in main.tf.

Fortinet           = "True"
Sophos             = "false"
Cisco              = "false"
Juniper            = "false"
PaloAlto           = "false"
Watchguard         = "false"

# Include EDR-Ubuntu test system?
EDR                = "false"

# Include specific # of Endpoint Win10 systems from Marketplace
w10                = 0

# Include specific # of Endpoint Win10 systems from Snapshot
w10snap            = 3

# Include specific # of Ubuntu Servers
Ubuntu             = 1
UbuntuVMsize       = "Standard_B4ms"

# Include specific # of "Windows 2019 Datacenter" Servers
Win19DC            = 1

# Include Terapackets Server?
Terapackets        = "False"