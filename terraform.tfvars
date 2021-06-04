RG_name            = "Lab-MorpheusMade-TF3"
RG_Env_Tag         = "Dev"
RG_SP_Name         = "Lab"

Requestor          = "Tester"
Owner              = "JIsley"

mgmt_Subnet1_name  = "mgmtSubnet"
int_Subnet2_name   = "internalSubnet"
ext_Subnet3_name   = "externalSubnet"

# Select true for the FW vendor of choice. 
# Defaults are false, only one needs to be passed as true from front-end.
# These are string inputs, and will be converted to lowercase + boolean in main.tf.

Fortinet           = "false"
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
w10snap            = 0

# Include specific # of Ubuntu Servers
Ubuntu             = 0
UbuntuVMsize       = "Standard_E2s_v3"

# Include specific # of "Windows 2019 Datacenter" Servers
Win19DC            = 0

# Include Terapackets Server?
Terapackets        = "False"
