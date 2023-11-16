# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.43.0"
    }
  }
}


# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  client_id                   = var.client_id
  client_secret               = var.client_secret
  tenant_id                   = var.tenant_id
  subscription_id             = var.subscription_id

}

# Create a resource group
resource "azurerm_resource_group" "data-api-vm-resource-group" {
  name     = "data-api-vm-resource-group"
  location = "West Europe"
  tags = {
    environment = "dev"
  }
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "data-api-vm-virtual-network" {
  name                = "data-api-vm-virtual-network"
  resource_group_name = azurerm_resource_group.data-api-vm-resource-group.name
  location            = azurerm_resource_group.data-api-vm-resource-group.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "data-api-vm-subnet" {
  name                 = "data-api-vm-internal-subnet"
  resource_group_name  = azurerm_resource_group.data-api-vm-resource-group.name
  virtual_network_name = azurerm_virtual_network.data-api-vm-virtual-network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "data-api-network-interface" {
  name                = "data-api-vm-network-interface"
  location            = azurerm_resource_group.data-api-vm-resource-group.location
  resource_group_name = azurerm_resource_group.data-api-vm-resource-group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.data-api-vm-subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "data-api-vm-virtual-machine" {
  name                = "data-api-vm-virtual-machine"
  resource_group_name = azurerm_resource_group.data-api-vm-resource-group.name
  location            = azurerm_resource_group.data-api-vm-resource-group.location
  size                = "Standard_B2ats_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.data-api-network-interface.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("./.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "debian"
    offer     = "debian-12"
    sku       = "12"
    version   = "latest"
  }
}