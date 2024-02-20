terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.75.0"
    }
  }
}

provider "azurerm" {
#  subscription_id = "6912d7a0-bc28-459a-9407-33bbba641c07"
#  client_id       = "ed5d6ac4-de15-4a24-b5d3-61812c9e9941"
#  client_secret   = "HOl7Q~23UVXp4J1SlBTsQQSR~dMk2CTsNERWH"
#  tenant_id       = "70c0f6d9-7f3b-4425-a6b6-09b47643ec58"
  features {}
}


#locals {
#  resource_group=var.rgname
#  location=var.location
#}


resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits = 4096
}

# We want to save the private key to our machine
# We can then use this key to connect to our Linux VM

resource "local_file" "linuxkey" {
  filename="linuxkey.pem"  
  content=tls_private_key.linux_key.private_key_pem 
}

data "azurerm_resource_group" "app_grp"{
  name=var.rgname
#  location=var.location
}

resource "azurerm_virtual_network" "app_network" {
  name                = var.vnet
  location            = var.location
  resource_group_name = var.rgname
  address_space       = var.vnet_cidr_prefix
}

resource "azurerm_subnet" "SubnetA" {
  name                 = var.subnet
  resource_group_name  = var.rgname
  virtual_network_name = var.vnet
  address_prefixes     = var.subnet1_cidr_prefix
  depends_on = [
    azurerm_virtual_network.app_network
  ]
}


resource "azurerm_network_interface" "app_interface" {
  name                = "app-interface"
  location            = var.location
  resource_group_name = var.rgname

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.app_public_ip.id
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_public_ip.app_public_ip
  ]
}

resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = var.vmname
  resource_group_name = var.rgname
  location            = var.location
  size                = "Standard_D2s_v3"
  admin_username      = var.vmuser  
  network_interface_ids = [
    azurerm_network_interface.app_interface.id,
  ]
  admin_ssh_key {
    username   = var.vmuser
    public_key = tls_private_key.linux_key.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface,
    tls_private_key.linux_key
  ]
}

resource "azurerm_public_ip" "app_public_ip" {
  name                = var.pip
  resource_group_name = var.rgname
  location            = var.location
  allocation_method   = "Static"
  depends_on = [
    data.azurerm_resource_group.app_grp
  ]
}
