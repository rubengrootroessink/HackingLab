data "template_file" "ws_smb_init" {
  template = file(var.ws_smb_install_script_tpl)

  vars = {
    ud_domain = var.domain_full
    
    ud_user_domain_join_username = var.user_domain_join_username
    ud_user_domain_join_pass = var.user_domain_join_pass

    ud_machine_hostname = var.ws_smb_hostname
    ud_machine_local_admin_pass = var.ws_smb_local_admin_pass
    ud_machine_install_script_path = var.ps_install_script_path
    ud_machine_transcript_path = var.ps_transcript_path

    ud_sched_task_path = var.ps_sched_task_path
    ud_sched_task_name = var.ws_smb_sched_task_name
    ud_sched_task_username = var.user_smb_sched_task_username
    ud_sched_task_pass = var.user_smb_sched_task_pass
    ud_sched_task_group = var.user_smb_sched_task_group

    ud_attacker_ip = var.network_wireguard_client_ip
  }
}

resource "aws_instance" "windows_ws_smb" {
  ami = data.aws_ami.windows.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.network_subnet.id
  private_ip = var.ws_smb_ip
  security_groups = [aws_security_group.network_secgroup.id]
  key_name = aws_key_pair.deployer.key_name
  get_password_data = "true"
  
  user_data = data.template_file.ws_smb_init.rendered

  tags = {
    Name = var.ws_smb_hostname
  }
}

output "ws_smb_password" {
  value = rsadecrypt(aws_instance.windows_ws_smb.password_data, file(var.ssh_key_private_path))
}
