data "template_file" "portal_init" {
  template = file(var.portal_install_script_tpl)

  vars = {
    ud_network_subnet_cidr = var.network_subnet_cidr
    ud_network_wireguard_client_ip = var.network_wireguard_client_ip
    ud_network_wireguard_client_port = var.network_wireguard_client_port
    ud_network_wireguard_client_config_location = var.network_wireguard_client_config_location
    ud_network_wireguard_server_ip = var.network_wireguard_server_ip
    ud_network_wireguard_server_port = var.network_wireguard_server_port
    ud_network_wireguard_server_config_location = var.network_wireguard_server_config_location
    ud_downloads_location = var.portal_downloads_location
    ud_downloads_owner = var.portal_downloads_owner
    ud_domain_controller_ip = var.dc_ip
  }
}

resource "aws_network_interface" "portal_interface" {
  subnet_id         = aws_subnet.network_subnet.id
  private_ips       = [var.portal_ip]
  security_groups   = [aws_security_group.network_secgroup.id]
  source_dest_check = false
}

resource "aws_instance" "ubuntu_portal" {
  ami = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name = aws_key_pair.deployer.key_name
  user_data = data.template_file.portal_init.rendered

  network_interface {
    network_interface_id = aws_network_interface.portal_interface.id
    device_index = 0
  }

  provisioner "file" {
    source = "./files/Rubeus.exe"
    destination = "/home/ubuntu/Rubeus.exe"

    connection {
      type = "ssh"
      user = var.portal_downloads_owner
      private_key = file(var.ssh_key_private_path)
      host = aws_instance.ubuntu_portal.public_ip
    }
  }
  
  provisioner "file" {
    source = "./files/SpoolSample.exe"
    destination = "/home/${var.portal_downloads_owner}/SpoolSample.exe"

    connection {
      type = "ssh"
      user = var.portal_downloads_owner
      private_key = file(var.ssh_key_private_path)
      host = aws_instance.ubuntu_portal.public_ip
    }
  }

  tags = {
    Name = var.portal_hostname
  }
}

output "portal_ipaddress" {
  value = aws_instance.ubuntu_portal.public_ip
}
