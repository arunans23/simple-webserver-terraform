provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
    name                = "${var.prefix}-network"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    tags = {
        reason = var.reason
    }
}

resource "azurerm_subnet" "internal" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = azurerm_resource_group.main.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "main" {
    name                = "${var.prefix}-nsg"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    security_rule {
        name                       = "deny-internet-inbound"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Deny"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "*"
        source_address_prefix      = "Internet"
        destination_address_prefix = "VirtualNetwork"
    }

    security_rule{
        name                        = "allow-vnet-inbound"
        priority                    = 150
        direction                   = "Inbound"
        access                      = "Allow"
        protocol                    = "*"
        source_port_range           = "*"
        destination_port_range      = "*"
        source_address_prefix       = "VirtualNetwork"
        destination_address_prefix  = "VirtualNetwork"
    }

    tags = {
        reason = var.reason
    }
}

resource "azurerm_network_interface" "main" {
    count               = var.vm_count
    name                = "${var.prefix}-nic-${var.server_names[count.index]}"
    resource_group_name = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location

    ip_configuration {
        name                          = "internalConfig"
        subnet_id                     = azurerm_subnet.internal.id
        private_ip_address_allocation = "Dynamic"
    }
    tags = {
        reason = var.reason
    }
}

resource "azurerm_public_ip" "main" {
    name                = "${var.prefix}-publicIp"
    resource_group_name = azurerm_resource_group.main.name
    location            = azurerm_resource_group.main.location
    allocation_method   = "Static"

    tags = {
        reason = var.reason
    }
}

resource "azurerm_lb" "main" {
    name                = "${var.prefix}-lb"
    location            = azurerm_resource_group.main.location
    resource_group_name = azurerm_resource_group.main.name

    frontend_ip_configuration {
        name                 = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.main.id
    }

    tags = {
        reason = var.reason
    }
}

resource "azurerm_lb_backend_address_pool" "main" {
    resource_group_name = azurerm_resource_group.main.name
    loadbalancer_id     = azurerm_lb.main.id
    name                = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
    count = var.vm_count

    network_interface_id    = azurerm_network_interface.main[count.index].id
    ip_configuration_name   = "internalConfig"
    backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_lb_rule" "main" {
    resource_group_name            = azurerm_resource_group.main.name
    loadbalancer_id                = azurerm_lb.main.id
    name                           = "${var.prefix}-lbrule"
    protocol                       = "TCP"
    frontend_port                  = 80
    backend_port                   = 80
    frontend_ip_configuration_name = "PublicIPAddress"
    backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
    probe_id                       = azurerm_lb_probe.main.id
}

resource "azurerm_lb_probe" "main" {
    resource_group_name = azurerm_resource_group.main.name
    loadbalancer_id     = azurerm_lb.main.id
    name                = "${var.prefix}-lbhealth"
    port                = 80
}

resource "azurerm_availability_set" "main" {
    name                        = "${var.prefix}-aset"
    location                    = azurerm_resource_group.main.location
    resource_group_name         = azurerm_resource_group.main.name
    platform_fault_domain_count = 2

    tags = {
        reason = var.reason
    }
}

resource "azurerm_linux_virtual_machine" "main" {
    count = var.vm_count

    name                            = "${var.prefix}-vm-${var.server_names[count.index]}"
    resource_group_name             = azurerm_resource_group.main.name
    location                        = azurerm_resource_group.main.location
    size                            = "Standard_D2s_v3"
    admin_username                  = var.username
    admin_password                  = var.password
    disable_password_authentication = false
    network_interface_ids = [
        azurerm_network_interface.main[count.index].id
    ]
    availability_set_id = azurerm_availability_set.main.id
    source_image_id     = var.packerImageId

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    tags = {
        reason  = var.reason
        name    = var.server_names[count.index]
        project = "simple-webserver"
    }
}

resource "azurerm_managed_disk" "main" {
    name                 = "${var.prefix}-md"
    location             = azurerm_resource_group.main.location
    resource_group_name  = azurerm_resource_group.main.name
    storage_account_type = "Standard_LRS"
    create_option        = "Empty"
    disk_size_gb         = "2"

    tags = {
        reason = var.reason
    }
}
