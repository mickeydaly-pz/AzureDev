

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = "${random_pet.prefix.id}-rg"
}

resource "azurerm_resource_group" "rg2" {
  location = var.resource_group_location
  name     = "${random_pet.prefix2.id}-rg"
}

resource "azurerm_resource_group" "rg3" {
  location = var.resource_group_location
  name     = "${var.customer_prefix}-ad-vnet-rg"
}

# Create virtual network
resource "azurerm_virtual_network" "pz-ad-vnet" {
  name                = "${var.customer_prefix}-ad-vnet"
  address_space       = ["10.5.1.0/27"]
  location            = azurerm_resource_group.rg3.location
  resource_group_name = azurerm_resource_group.rg3.name
  dns_servers = [ "10.5.1.4", "10.5.1.5", "8.8.8.8", "8.8.4.4" ]
}

# Create subnet
resource "azurerm_subnet" "pz-ad-subnet" {
  name                 = "${var.customer_prefix}-ad-subnet"
  resource_group_name  = azurerm_resource_group.rg3.name
  virtual_network_name = azurerm_virtual_network.pz-ad-vnet.name
  address_prefixes     = ["10.5.1.0/28"]
}

# Create public IPs
resource "azurerm_public_ip" "pz-ad-pip" {
  name                = "${random_pet.prefix.id}-public-ip"
  location            = azurerm_resource_group.rg3.location
  resource_group_name = azurerm_resource_group.rg3.name
  allocation_method   = "Dynamic"
}

# Create public IPs
resource "azurerm_public_ip" "pz-ad-pip2" {
  name                = "${random_pet.prefix2.id}-public-ip"
  location            = azurerm_resource_group.rg3.location
  resource_group_name = azurerm_resource_group.rg3.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "pz-ad-nsg" {
  name                = "${var.customer_prefix}-ad-nsg"
  location            = azurerm_resource_group.rg3.location
  resource_group_name = azurerm_resource_group.rg3.name

  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.source_ip
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "pz-ad-nic" {
  name                = "${random_pet.prefix.id}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "pz-ad-nic-config"
    subnet_id                     = azurerm_subnet.pz-ad-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.5.1.4"
    public_ip_address_id          = azurerm_public_ip.pz-ad-pip.id
  }
}

# Create network interface
resource "azurerm_network_interface" "pz-ad-nic2" {
  name                = "${random_pet.prefix2.id}-nic"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  depends_on = [ azurerm_virtual_machine_extension.dc_install ]
  ip_configuration {
    name                          = "pz-ad-nic-config2"
    subnet_id                     = azurerm_subnet.pz-ad-subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address = "10.5.1.5"
    public_ip_address_id          = azurerm_public_ip.pz-ad-pip2.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "pz-ad-nic-nsg" {
  network_interface_id      = azurerm_network_interface.pz-ad-nic.id
  network_security_group_id = azurerm_network_security_group.pz-ad-nsg.id
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "pz-ad-ni2c-nsg" {
  network_interface_id      = azurerm_network_interface.pz-ad-nic2.id
  network_security_group_id = azurerm_network_security_group.pz-ad-nsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "pz-ad-sa" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "pz-ad-sa2" {
  name                     = "diag${random_id.random_id2.hex}"
  location                 = azurerm_resource_group.rg2.location
  resource_group_name      = azurerm_resource_group.rg2.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


# Create virtual machine
resource "azurerm_windows_virtual_machine" "main" {
  name                  = "${random_pet.prefix.id}-dc"
  admin_username        = "maadmin"
  admin_password        = random_password.password_local.result
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.pz-ad-nic.id]
  size                  = "Standard_D2as_v5"
  patch_mode = "AutomaticByPlatform"
  os_disk {
    name                 = "${random_pet.prefix.id}-os"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }


  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.pz-ad-sa.primary_blob_endpoint
  }
}

resource "azurerm_managed_disk" "main_data" {
  name                 = "${random_pet.prefix.id}-data"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
}

resource "azurerm_virtual_machine_data_disk_attachment" "main_data_attachment" {
  managed_disk_id    = azurerm_managed_disk.main_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.main.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_managed_disk" "backup_data" {
  name                 = "${random_pet.prefix2.id}-data"
  location             = azurerm_resource_group.rg2.location
  resource_group_name  = azurerm_resource_group.rg2.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 20
}

resource "azurerm_virtual_machine_data_disk_attachment" "backup_data_attachment" {
  managed_disk_id    = azurerm_managed_disk.backup_data.id
  virtual_machine_id = azurerm_windows_virtual_machine.backup.id
  lun                = "10"
  caching            = "ReadWrite"
}

# Create virtual machine
resource "azurerm_windows_virtual_machine" "backup" {
  name                  = "${random_pet.prefix2.id}-dc"
  admin_username        = "maadmin"
  admin_password        = random_password.password_local2.result
  location              = azurerm_resource_group.rg2.location
  resource_group_name   = azurerm_resource_group.rg2.name
  network_interface_ids = [azurerm_network_interface.pz-ad-nic2.id]
  size                  = "Standard_D2as_v5"
  patch_mode = "AutomaticByPlatform"
  depends_on = [ azurerm_virtual_machine_extension.dc_install ]
  os_disk {
    name                 = "${random_pet.prefix2.id}-os"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }


  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.pz-ad-sa2.primary_blob_endpoint
  }
}

resource "azurerm_virtual_machine_extension" "dc_install" {
  name                       = "${random_pet.prefix.id}-dc"
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true
  depends_on = [ azurerm_managed_disk.main_data ]
  
  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/mickeydaly-pz/AzureDev/main/Install-Domain.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive \"./Install-Domain.ps1 -dsrmPassword (ConvertTo-SecureString '${random_password.password_dsrm.result}' -AsPlainText -Force) -localPassword (ConvertTo-SecureString '${random_password.password_local.result}' -AsPlainText -Force) -domainName 'ad.pgzr.io' -dnsExists $false -username 'maadmin'\""
    }
  SETTINGS
}

resource "azurerm_virtual_machine_extension" "dc_install2" {
  name                       = "${random_pet.prefix2.id}-dc"
  virtual_machine_id         = azurerm_windows_virtual_machine.backup.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.8"
  auto_upgrade_minor_version = true
  depends_on = [ azurerm_virtual_machine_extension.dc_install, azurerm_managed_disk.backup_data ]
  settings = <<SETTINGS
    {
      "fileUris": ["https://raw.githubusercontent.com/mickeydaly-pz/AzureDev/main/Install-Domain.ps1"],
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -NoProfile -NonInteractive \"./Install-Domain.ps1 -dsrmPassword (ConvertTo-SecureString '${random_password.password_dsrm2.result}' -AsPlainText -Force) -localPassword (ConvertTo-SecureString '${random_password.password_local.result}' -AsPlainText -Force) -domainName 'ad.pgzr.io' -dnsExists $true -username 'AD\\maadmin'\""
    }
  SETTINGS
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

resource "random_id" "random_id2" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

resource "random_password" "password_local" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
  override_special = "!?*()"
}

resource "random_password" "password_local2" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
  override_special = "!?*()"
}

resource "random_password" "password_dsrm" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
  override_special = "!?*()"
}

resource "random_password" "password_dsrm2" {
  length      = 20
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
  special     = true
  override_special = "!?*()"
}

resource "random_pet" "prefix" {
  prefix = var.customer_prefix
  separator = "-"
}

resource "random_pet" "prefix2" {
  prefix = var.customer_prefix
  separator = "-"
}