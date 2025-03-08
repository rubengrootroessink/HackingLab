data "template_file" "dc_init" {
  template = file(var.dc_install_script_tpl)
  
  vars = {
    ud_domain = var.domain_full
    ud_domain_short = var.domain_short
    ud_domain_dsrm = var.domain_dsrm
    
    ud_user_domain_join_username = var.user_domain_join_username
    ud_user_domain_join_pass = var.user_domain_join_pass
    
    ud_machine_hostname = var.dc_hostname
    ud_machine_local_admin_pass = var.dc_local_admin_pass
    ud_machine_install_script_path = var.ps_install_script_path
    ud_machine_transcript_path = var.ps_transcript_path

    ud_sched_task_path = var.ps_sched_task_path

    # Attack Path 1
    ud_user_smb_sched_task_username = var.user_smb_sched_task_username
    ud_user_smb_sched_task_pass = var.user_smb_sched_task_pass
    ud_user_smb_sched_task_group = var.user_smb_sched_task_group
    
    ud_user_lsass_user_username = var.user_lsass_user_username
    ud_user_lsass_user_pass = var.user_lsass_user_pass
    ud_user_lsass_user_group = var.user_lsass_user_group

    ud_user_desktop_file_username = var.user_desktop_file_username
    ud_user_desktop_file_pass = var.user_desktop_file_pass
    ud_user_desktop_file_group = var.user_desktop_file_group

    ud_machine_unconstrained_delegation = var.ms_ud_hostname
    
    # Attack Path 2
    ud_user_http_sched_task_username = var.user_http_sched_task_username
    ud_user_http_sched_task_pass = var.user_http_sched_task_pass
    ud_user_http_sched_task_group = var.user_http_sched_task_group
    
    ud_user_ldap_empty_pass_username = var.user_ldap_empty_pass_username
    
    # Attack Path 3
    ud_user_ldap_comment_username = var.user_ldap_comment_username
    ud_user_ldap_comment_pass = var.user_ldap_comment_pass
    ud_user_ldap_comment_group = var.user_ldap_comment_group

    ud_machine_spn_cd_source = var.ms_cd_hostname
    ud_machine_spn_cd_destination = var.ms_kerberos_hostname
    ud_machine_spn_cd_type = var.ms_cd_spn_name

    ud_machine_portal_ip = var.portal_ip

    ud_machine_kerberos_hostname = var.ms_kerberos_hostname
    ud_machine_kerberos_local_admin_pass = var.ms_kerberos_local_admin_pass
    ud_machine_kerberos_sched_task_name = var.ms_kerberos_sched_task_name
    
    ud_download_location = var.download_location_path

    ud_user_kerberos_ticket_username = var.user_kerberos_ticket_username
    ud_user_kerberos_ticket_pass = var.user_kerberos_ticket_pass

    # Attack Path 4
    ud_user_spn_username = var.user_spn_username
    ud_user_spn_pass = var.user_spn_pass
    ud_user_spn_group = var.user_spn_group

    ud_machine_rbcd_source = var.ms_rbcd_hostname
    ud_machine_rbcd_destination = var.ms_lsa_secret_hostname
    
    ud_user_lsa_secret_username = var.user_lsa_secret_username
    ud_user_lsa_secret_pass = var.user_lsa_secret_pass
    ud_user_lsa_secret_group = var.user_lsa_secret_group
    
    ud_user_lsass_da_username = var.user_lsass_da_username
    ud_user_lsass_da_pass = var.user_lsass_da_pass
  }
}

resource "aws_instance" "windows_dc" {
  ami = data.aws_ami.windows.id
  instance_type = var.instance_type
  subnet_id = aws_subnet.network_subnet.id
  private_ip = var.dc_ip
  security_groups = [aws_security_group.network_secgroup.id]
  key_name = aws_key_pair.deployer.key_name
  get_password_data = "true"
  user_data = data.template_file.dc_init.rendered
  
  tags = {
    Name = var.dc_hostname
  }
}

output "dc_password" {
  value = rsadecrypt(aws_instance.windows_dc.password_data, file(var.ssh_key_private_path))
}
