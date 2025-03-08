### AWS-Specific Information ###
variable "aws_access_key" {
  description = "Long term credential for an IAM user or the AWS account root user. Access keys do not expire."
  type = string
  default = "" # TODO
}

variable "aws_secret_key" {
  description = "Secret key corresponding to our Access Key"
  type = string
  default = "" # TODO
}

variable "aws_region" {
  description = "The location where we would like to deploy our project. In this case Frankfurt."
  type = string
  default = "eu-central-1"
}

### SSH Credentials ###
variable "ssh_key_name" {
  description = "The display name of our SSH key in the AWS. Public key only."
  type = string
  default = "redteam-env-public-key"
}

variable "ssh_key_public_path" {
  description = "The path to our public SSH key, to be used by AWS to control access to EC instances."
  type = string
  default = "" # TODO
}

variable "ssh_key_private_path" {
  description = "The path to our private SSH key, to be used to retrieve Windows Admin credentials."
  type = string
  default = "" # TODO
}

### Generic EC2 Settings ###
variable "instance_type" {
  description = "The instance type to be used by Terraform. In my case t2.large worked best in terms of performance. More expensive though."
  type = string
  default = "t2.large"
}

# https://github.com/guillermo-musumeci/terraform-aws-latest-ami/blob/master/Get-Latest-Windows-AMI.tf
data "aws_ami" "windows" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["Windows_Server-2022-English-Full-Base*"] # To be updated to 2025 in the future
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["amazon"]
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

### Network Settings ###
variable "network_vpc_name" {
  description = "The name of the Virtual Private Cloud to be deployed."
  type = string
  default = "Redteam VPC"
}

variable "network_vpc_cidr" {
  description = "The CIDR of the Virtual Private Cloud to be deployed."
  type = string
  default = "192.168.0.0/24"
}

variable "network_subnet_name" {
  description = "The name of the Subnet to be deployed in our VPC."
  type = string
  default = "Redteam Subnet"
}

variable "network_subnet_cidr" {
  description = "The CIDR of the Subnet to be deployed in our VPC."
  type = string
  default = "192.168.0.0/24"
}

variable "network_secgroup_name" {
  description = "The Name of the Security Group to be used."
  type = string
  default = "Redteam Security Group"
}

variable "network_gateway_name" {
  description = "The Name of the Gateway to be used."
  type = string
  default = "Redteam Gateway"
}

variable "network_routetable_name" {
  description = "The Name of the Route Table to be used."
  type = string
  default = "Redteam Route Table"
}

variable "network_vpn_ip_address" {
  description = "The CIDR block of a VPN server that would allow access to the environment."
  type = string
  default = "0.0.0.0/0"
}

variable "network_wireguard_client_ip" {
  description = "The IP address of the Wireguard client."
  type = string
  default = "192.168.100.1"
}

variable "network_wireguard_client_port" {
  description = "The port used by the Wireguard client."
  type = number
  default = 51821
}

variable "network_wireguard_client_config_location" {
  description = "The location where to store the configuration for the Wireguard client. To be extracted for use in engagement."
  type = string
  default = "/home/ubuntu/wireguard.conf"
}

variable "network_wireguard_server_ip" {
  description = "The IP address of the Wireguard server."
  type = string
  default = "192.168.100.2"
}

variable "network_wireguard_server_port" {
  description = "The port used by the Wireguard server. To be allowed through to the VPC."
  type = number
  default = 51822
}

variable "network_wireguard_server_config_location" {
  description = "The location where to store the configuration for the Wireguard server. Default Wireguard location."
  type = string
  default = "/etc/wireguard/wg0.conf"
}

variable "portal_downloads_location" {
  description = "The location of the portal on the internet-connected machine."
  type = string
  default = "/home/ubuntu/Downloads"
}

variable "portal_downloads_owner" {
  description = "The owner of the files hosted through the portal."
  type = string
  default = "ubuntu"
}

### Domain Settings ###
variable "domain_full" {
  description = "The full name for the domain to be used."
  type = string
  default = "redteam.local"
}

variable "domain_short" {
  description = "The short name for the domain to be used."
  type = string
  default = "redteam"
}

variable "domain_dsrm" {
  description = "The DSRM password of the newly created domain."
  type = string
  default = "DRg0197egXqHdIqjZ7"
}

### Portal / Interface Machine (Kali Linux) settings ###
variable "portal_hostname" {
  description = "Hostname"
  type = string
  default = "PORTAL01"
}

variable "portal_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.37"
}

variable "portal_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./portal_userdata.tpl"
}

### Local locations of hacking files to be uploaded to our portal ###
variable "file_location_rubeus" {
  description = "Local file location where a version of Rubeus (.exe) has been stored"
  type = string
  default = "./files/Rubeus.exe"
}

variable "file_location_spoolsample" {
  description = "Local file location where a version of SpoolSample (.exe) has been stored"
  type = string
  default = "./files/SpoolSample.exe"
}

### Generic Windows settings ###
variable "ps_install_script_path" {
  description = "The location of the Powershell installation script of machines."
  type = string
  default = "C:\\Windows\\Temp\\script.ps1"
}

variable "ps_transcript_path" {
  description = "The location of the Powershell transcript for debugging rollout of machines."
  type = string
  default = "C:\\Windows\\Temp\\pslog.txt"
}

variable "ps_sched_task_path" {
  description = "The location of a scheduled machine on several of the Windows machines."
  type = string
  default = "C:\\Windows\\Temp\\scheduled.ps1"
}

variable "download_location_path" {
  description = "The path on machines where to store specific tools used to built the lab (Rubeus/PsExec)"
  type = string
  default = "C:\\Windows\\Temp"
}

### Management Machine to login via RDP to domain-joined machines ###
variable "srv_mgmt_hostname" {
  description = "Hostname"
  type = string
  default = "MANAGER"
}

variable "srv_mgmt_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.244"
}

variable "srv_mgmt_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "44Tqfk9Ts5sV4sgcCW"
}

variable "srv_mgmt_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./srv_mgmt_userdata.tpl"
}

variable "srv_mgmt_sched_task_name" {
  description = "Name of ScheduledJob that performs logins to domain machines"
  type = string
  default = "Login"
}

### Domain Controller ###
variable "dc_hostname" {
  description = "Hostname"
  type = string
  default = "DC01"
}

variable "dc_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.100"
}

variable "dc_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "P6VHgD55Ah9CjUvT8q"
}

variable "dc_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./dc_userdata.tpl"
}

### Attack Path 1 ###
### 'Workstation' with recurring SMB request to attacker machine ###
variable "ws_smb_hostname" {
  description = "Hostname"
  type = string
  default = "WKSTN01"
}

variable "ws_smb_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.11"
}

variable "ws_smb_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "tu70cbVQ72bIAg0kKt"
}

variable "ws_smb_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ws_smb_userdata.tpl"
}

variable "ws_smb_sched_task_name" {
  description = "Name of ScheduledJob that runs recurring SMB request."
  type = string
  default = "SMBRequest"
}

### Server with user account in LSASS memory ###
variable "ms_lsass_user_hostname" {
  description = "Hostname"
  type = string
  default = "FILE01"
}

variable "ms_lsass_user_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.21"
}

variable "ms_lsass_user_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "hnsev20ZTsgR7M71Zt"
}

variable "ms_lsass_user_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ms_lsass_user_userdata.tpl"
}

### Server with Desktop file containing credentials ###
variable "ms_desktop_file_hostname" {
  description = "Hostname"
  type = string
  default = "MGMT01"
}

variable "ms_desktop_file_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.31"
}

variable "ms_desktop_file_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "40Bt6bdILwo85rR3zJ"
}

variable "ms_desktop_file_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ms_desktop_file_userdata.tpl"
}

variable "ms_desktop_file_file_path" {
  description = "Location where to store the file containing credentials."
  type = string
  default = "C:\\Users\\Administrator\\Desktop\\pass.txt"
}

### Server with Unconstrained Delegation enabled ###
variable "ms_ud_hostname" {
  description = "Hostname"
  type = string
  default = "WEB01"
}

variable "ms_ud_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.41"
}

variable "ms_ud_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "86NKKhkl3xpO9zURl6"
}

variable "ms_ud_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ms_ud_userdata.tpl"
}

### Attack Path 2 (3 and 4) ###
### 'Workstation' with recurring HTTP request to attacker machine ###
variable "ws_http_hostname" {
  description = "Hostname"
  type = string
  default = "WKSTN02"
}

variable "ws_http_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.12"
}

variable "ws_http_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "Vrmf0VOylB5q17E66g"
}

variable "ws_http_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ws_http_userdata.tpl"
}

variable "ws_http_sched_task_name" {
  description = "Name of ScheduledJob that runs recurring HTTP request."
  type = string
  default = "HTTPRequest"
}

### Attack Path 3 ###
### Server with shared local Administrator password ###
variable "ms_shared_admin_hostname" {
  description = "Hostname"
  type = string
  default = "ENG01"
}

variable "ms_shared_admin_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.22"
}

variable "ms_shared_admin_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "fBiSE64T3sMX51EZUS"
}

variable "ms_shared_admin_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ms_shared_admin_userdata.tpl"
}

### Server with shared local admin and Constrained Delegation enabled ###
variable "ms_cd_hostname" {
  description = "Hostname"
  type = string
  default = "WEB02"
}

variable "ms_cd_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.32"
}

variable "ms_cd_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "Dz45hyy98yPEX9Xil0"
}

variable "ms_cd_install_script_tpl" {
  description = "(Local) admin password"
  type = string
  default = "./ms_cd_userdata.tpl"
}

variable "ms_cd_spn_name" {
  description = "The name of the SPN enabling Constrained Delegation."
  type = string
  default = "MSSQL"
}

### Server with Domain Administrator Kerberos ticket ###
variable "ms_kerberos_hostname" {
  description = "Hostname"
  type = string
  default = "DATA02"
}

variable "ms_kerberos_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.42"
}

variable "ms_kerberos_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "oBy0nWrH9mxv6P2S7Y"
}

variable "ms_kerberos_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ms_kerberos_userdata.tpl"
}

variable "ms_kerberos_sched_task_name" {
  description = "Name of ScheduledTask that injects a Kerberos ticket into a new cmd.exe process at startup."
  type = string
  default = "KerbInject"
}

### Attack Path 4 ###
### Server with RBCD configured ###
variable "ms_rbcd_hostname" {
  description = "Hostname"
  type = string
  default = "WEB03"
}

variable "ms_rbcd_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.23"
}

variable "ms_rbcd_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "Mb8k6HhVHBZN4H2dPJ"
}

variable "ms_rbcd_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ms_rbcd_userdata.tpl"
}

### Server with LSA Secret ###
variable "ms_lsa_secret_hostname" {
  description = "Hostname"
  type = string
  default = "DATA03"
}

variable "ms_lsa_secret_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.33"
}

variable "ms_lsa_secret_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "Yt261zWQJVQCHOzrIL"
}

variable "ms_lsa_secret_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ms_lsa_secret_userdata.tpl"
}

### Server with DA in LSASS ###
variable "ms_lsass_da_hostname" {
  description = "Hostname"
  type = string
  default = "MGMT03"
}

variable "ms_lsass_da_ip" {
  description = "IP address"
  type = string
  default = "192.168.0.43"
}

variable "ms_lsass_da_local_admin_pass" {
  description = "(Local) admin password"
  type = string
  default = "J2uJj9AIrwTw6ZVIqG"
}

variable "ms_lsass_da_install_script_tpl" {
  description = "User data installation script"
  type = string
  default = "./ms_lsass_da_userdata.tpl"
}

### Domain Users ###
variable "user_domain_join_username" {
  description = "Username of the account to join machines to the domain. Disabled after usage."
  type = string
  default = "svc_join"
}

variable "user_domain_join_pass" {
  description = "Username of the account to join machines to the domain. Disabled after usage."
  type = string
  default = "3eKld8jJ7sy0e7ThZ"
}

variable "user_smb_sched_task_username" {
  description = "The (domain) user running a scheduled task that performs a SMB request to our attacker machine."
  type = string
  default = "adm_fileserver"
}

variable "user_smb_sched_task_pass" {
  description = "The password of the (domain) user running a scheduled task that performs a SMB request to our attacker machine."
  type = string
  default = "z1TTDvsET9PVv7tPAq"
}

variable "user_smb_sched_task_group" {
  description = "The group of the (domain) user running a scheduled task that performs a SMB request to our attacker machine."
  type = string
  default = "FileServer Admins"
}

variable "user_lsass_user_username" {
  description = "The (domain) user that performs recurring RDP logins to the Server which has SMB enabled."
  type = string
  default = "adm_mgmtserver"
}

variable "user_lsass_user_pass" {
  description = "The password of the (domain) user that performs recurring RDP logins to the Server which has SMB enabled."
  type = string
  default = "N7kCIMd33CXIS482vF"
}

variable "user_lsass_user_group" {
  description = "The group of the (domain) user that performs recurring RDP logins to the Server which has SMB enabled."
  type = string
  default = "MGMTServer Admins"
}

variable "user_desktop_file_username" {
  description = "The (domain) user which credentials can be found in a Desktop file."
  type = string
  default = "adm_webserver"
}

variable "user_desktop_file_pass" {
  description = "The password of the (domain) user which credentials can be found in a Desktop file."
  type = string
  default = "3HxTK4KF82HXifaJMK"
}

variable "user_desktop_file_group" {
  description = "The group of the (domain) user which credentials can be found in a Desktop file."
  type = string
  default = "WebServer Admins"
}

variable "user_http_sched_task_username" {
  description = "The (domain) user running a scheduled task that performs a HTTP request to our attacker machine."
  type = string
  default = "websurfer"
}

variable "user_http_sched_task_pass" {
  description = "The password of the (domain) user running a scheduled task that performs a HTTP request to our attacker machine."
  type = string
  default = "lx0Of7BSD5616AfADj"
}

variable "user_http_sched_task_group" {
  description = "The password of the (domain) user running a scheduled task that performs a HTTP request to our attacker machine."
  type = string
  default = "Workstation Admins"
}

variable "user_ldap_empty_pass_username" {
  description = "This Domain Administrator has an empty password in LDAP (and PASS_NOT_REQUIRED set to bypass password strength settings)"
  type = string
  default = "adm_domain"
}

variable "user_ldap_comment_username" {
  description = "The (domain) user which has its password as a comment in LDAP."
  type = string
  default = "adm_engserver"
}

variable "user_ldap_comment_pass" {
  description = "The password of the (domain) user which has its password as a comment in LDAP."
  type = string
  default = "MOdfr391tU3U2jS9vY"
}

variable "user_ldap_comment_group" {
  description = "The group of the (domain) user which has its password as a comment in LDAP."
  type = string
  default = "Engineering Admins"
}

variable "user_shared_local_admin_username" {
  description = "The local Administrator user shared between two machines."
  type = string
  default = "BackupAdmin"
}

variable "user_shared_local_admin_pass" {
  description = "The password of the local Administrator user shared between two machines."
  type = string
  default = "ebvsBJXeOTu48s766n"
}

variable "user_kerberos_ticket_username" {
  description = "The Domain Administrator which has a Kerberos ticket stored in memory on a certain machine."
  type = string
  default = "adm_da"
}

variable "user_kerberos_ticket_pass" {
  description = "The password of the Domain Administrator which has a Kerberos ticket stored in memory on a certain machine."
  type = string
  default = "avfV0aQpn90l07d8xn"
}

variable "user_spn_username" {
  description = "Domain (user) with SPN set (and easy password), PASS_NOT_REQUIRED"
  type = string
  default = "adm_webautomate"
}

variable "user_spn_pass" {
  description = "Password of domain (user) with SPN set (and easy password)"
  type = string
  default = "!123ABCabc" # Password present in rockyou.txt
}

variable "user_spn_group" {
  description = "Group of domain (user) with SPN set (and easy password)"
  type = string
  default = "WebAutomation Admins"
}

variable "user_lsa_secret_task_name" {
  description = "Taskname of the task that registers the credentials of the LSA user."
  type = string
  default = "WinSVC"
}

variable "user_lsa_secret_username" {
  description = "Domain (user) which username and password are stored as LSA secret on a machine."
  type = string
  default = "adm_mngr"
}

variable "user_lsa_secret_pass" {
  description = "Password of Domain (user) which username and password are stored as LSA secret on a machine."
  type = string
  default = "vnZawt0HV4ORM8tMcB"
}

variable "user_lsa_secret_group" {
  description = "Group of Domain (user) which username and password are stored as LSA secret on a machine."
  type = string
  default = "Management Admins"
}

variable "user_lsass_da_username" {
  description = "Domain Admin which has an LSASS session on a certain machine."
  type = string
  default = "adm_dc"
}

variable "user_lsass_da_pass" {
  description = "Password of Domain Admin which has an LSASS session on a certain machine."
  type = string
  default = "2r09Y6lfCDGko9tddt"
}
