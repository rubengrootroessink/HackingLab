data "template_file" "srv_mgmt_init" {
  template = file(var.srv_mgmt_install_script_tpl)

  vars = {
    ud_domain = var.domain_full
    
    ud_machine_hostname = var.srv_mgmt_hostname
    ud_machine_local_admin_pass = var.srv_mgmt_local_admin_pass
    ud_machine_install_script_path = var.ps_install_script_path
    ud_machine_transcript_path = var.ps_transcript_path
    
    ud_ms_smb_ip = var.ms_lsass_user_ip
    ud_ms_smb_username = var.user_lsass_user_username
    ud_ms_smb_pass = var.user_lsass_user_pass
    ud_machine_sched_task_lsass_user_name = "LOGINUSER"
    ud_machine_sched_task_lsass_user_path = "C:\\Windows\\Temp\\scheduled_user.ps1"

    ud_ms_lsass_da_ip = var.ms_lsass_da_ip
    ud_ms_lsass_da_username = var.user_lsass_da_username
    ud_ms_lsass_da_pass = var.user_lsass_da_pass
    ud_machine_sched_task_lsass_da_name = "LOGINDA"
    ud_machine_sched_task_lsass_da_path = "C:\\Windows\\Temp\\scheduled_da.ps1"
  }
}

resource "aws_instance" "windows_srv_mgmt" {
  ami = data.aws_ami.windows.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.network_subnet.id
  private_ip = var.srv_mgmt_ip
  security_groups = [aws_security_group.network_secgroup.id]
  key_name = aws_key_pair.deployer.key_name
  get_password_data = "true"
  
  user_data = data.template_file.srv_mgmt_init.rendered

  tags = {
    Name = var.srv_mgmt_hostname
  }
}

output "srv_mgmt_password" {
  value = rsadecrypt(aws_instance.windows_srv_mgmt.password_data, file(var.ssh_key_private_path))
}
