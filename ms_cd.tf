data "template_file" "ms_cd_init" {
  template = file(var.ms_cd_install_script_tpl)

  vars = {
    ud_domain = var.domain_full

    ud_user_domain_join_username = var.user_domain_join_username
    ud_user_domain_join_pass = var.user_domain_join_pass

    ud_machine_hostname = var.ms_cd_hostname
    ud_machine_local_admin_pass = var.ms_cd_local_admin_pass
    ud_machine_install_script_path = var.ps_install_script_path
    ud_machine_transcript_path = var.ps_transcript_path

    ud_user_shared_local_admin_username = var.user_shared_local_admin_username
    ud_user_shared_local_admin_pass = var.user_shared_local_admin_pass
  }
}

resource "aws_instance" "windows_ms_cd" {
  ami = data.aws_ami.windows.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.network_subnet.id
  private_ip = var.ms_cd_ip
  security_groups = [aws_security_group.network_secgroup.id]
  key_name = aws_key_pair.deployer.key_name
  get_password_data = "true"
  
  user_data = data.template_file.ms_cd_init.rendered

  tags = {
    Name = var.ms_cd_hostname
  }
}

output "ms_cd_password" {
  value = rsadecrypt(aws_instance.windows_ms_cd.password_data, file(var.ssh_key_private_path))
}
