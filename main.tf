# Generate SSH key pair to use as follows:
# ssh-keygen -t rsa -m "PEM"
# Legacy PEM format is required by AWS, RSA is required for Wndows machines

terraform {
  required_version = ">= 1.0"
  required_providers {
    template = {
      source = "hashicorp/template"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.aws_region
}

resource "aws_key_pair" "deployer" {
  key_name = var.ssh_key_name
  public_key = file(var.ssh_key_public_path)
}

resource "aws_vpc" "network_vpc" {
  cidr_block = var.network_vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.network_vpc_name
  }
}

resource "aws_vpc_dhcp_options" "network_vpc_dhcp_settings" {
  domain_name_servers = [var.dc_ip, "8.8.8.8"]
}

resource "aws_vpc_dhcp_options_association" "network_vpc_dns_resolver" {
  vpc_id = aws_vpc.network_vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.network_vpc_dhcp_settings.id
}

resource "aws_subnet" "network_subnet" {
  vpc_id = aws_vpc.network_vpc.id

  cidr_block = var.network_subnet_cidr
  map_public_ip_on_launch = true

  tags = {
    Name = var.network_subnet_name
  }
}

resource "aws_security_group" "network_secgroup" {
  name = var.network_secgroup_name
  vpc_id = aws_vpc.network_vpc.id

  ingress {
    description = "SSH access to all machines"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.network_vpn_ip_address]
  }

  ingress {
    description = "Wireguard connection"
    from_port = var.network_wireguard_server_port
    to_port = var.network_wireguard_server_port
    protocol = "udp"
    cidr_blocks = [var.network_vpn_ip_address]
  }

  ingress {
    description = "Allow all connections within VPC"
    from_port = 0
    to_port = 0
    protocol = "all"
    self = true
  }
  
  egress {
    description = "Allow all connections to the outside from within the VPC"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.network_secgroup_name
  }
}

resource "aws_internet_gateway" "network_gateway" {
  vpc_id = aws_vpc.network_vpc.id

  tags = {
    Name = var.network_gateway_name
  }
}

resource "aws_route_table" "network_routetable" {
  vpc_id = aws_vpc.network_vpc.id
  
  route {
    cidr_block = var.network_vpn_ip_address
    gateway_id = aws_internet_gateway.network_gateway.id
  }

  route {
    cidr_block = "${var.network_wireguard_client_ip}/32"
    network_interface_id = aws_network_interface.portal_interface.id
  }

  tags = {
    Name = var.network_routetable_name
  }
}

resource "aws_route_table_association" "network_routetable_association" {
  subnet_id = aws_subnet.network_subnet.id
  route_table_id = aws_route_table.network_routetable.id
}
