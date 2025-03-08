<powershell>
Set-ExecutionPolicy Unrestricted -Force

$installScriptPath = "${ud_machine_install_script_path}"
$transcriptPath = "${ud_machine_transcript_path}"
#Start-Transcript -Append -Path $transcriptPath

# Changes the password of the Domain Administrator 'Administrator' user
net user Administrator ${ud_machine_local_admin_pass} /Y

# Creates a user for adding each computer to the domain
net user ${ud_user_domain_join_username} ${ud_user_domain_join_pass} /add /Y

# Attack Path 1
# Creates a user to schedule recurring SMB task
net user ${ud_user_smb_sched_task_username} ${ud_user_smb_sched_task_pass} /add /Y
net localgroup "${ud_user_smb_sched_task_group}" /add /Y
net localgroup "${ud_user_smb_sched_task_group}" ${ud_user_smb_sched_task_username} /add /Y

# Creates a user which will be used to login with via RDP (headless)
net user ${ud_user_lsass_user_username} ${ud_user_lsass_user_pass} /add /Y
net localgroup "${ud_user_lsass_user_group}" /add /Y
net localgroup "${ud_user_lsass_user_group}" ${ud_user_lsass_user_username} /add /Y

# Creates a user which credentials will be stored in a Desktop file
net user ${ud_user_desktop_file_username} ${ud_user_desktop_file_pass} /add /Y
net localgroup "${ud_user_desktop_file_group}" /add /Y
net localgroup "${ud_user_desktop_file_group}" ${ud_user_desktop_file_username} /add /Y

# Attack Path 2
# Creates a user to schedule recurring HTTP task
net user ${ud_user_http_sched_task_username} ${ud_user_http_sched_task_pass} /add /Y
net localgroup "${ud_user_http_sched_task_group}" /add /Y
net localgroup "${ud_user_http_sched_task_group}" ${ud_user_http_sched_task_username} /add /Y

# Creates a user which has an empty/blank password (PASS_NOT_REQD)
net user ${ud_user_ldap_empty_pass_username} Test1234! /add /Y

# Attack Path 3
# Creates a user which has its password stored in LDAP
net user ${ud_user_ldap_comment_username} ${ud_user_ldap_comment_pass} /comment:"Password: ${ud_user_ldap_comment_pass}" /add /Y
net localgroup "${ud_user_ldap_comment_group}" /add /Y
net localgroup "${ud_user_ldap_comment_group}" ${ud_user_ldap_comment_username} /add /Y

# Creates a user (Domain Admin) which has its Kerberos ticket on a certain machine
net user ${ud_user_kerberos_ticket_username} ${ud_user_kerberos_ticket_pass} /add /Y

# Attack Path 4
# Creates a user which has a SPN set.
net user ${ud_user_spn_username} ${ud_user_spn_pass} /add /Y
net localgroup "${ud_user_spn_group}" /add /Y
net localgroup "${ud_user_spn_group}" ${ud_user_spn_username} /add /Y

# Creates a user which has its password stored as an LSA secret on a certain machine.
net user ${ud_user_lsa_secret_username} ${ud_user_lsa_secret_pass} /add /Y
net localgroup "${ud_user_lsa_secret_group}" /add /Y
net localgroup "${ud_user_lsa_secret_group}" ${ud_user_lsa_secret_username} /add /Y

# Creates a Domain Administrator which has an LSASS session somewhere.
net user ${ud_user_lsass_da_username} ${ud_user_lsass_da_pass} /add /Y

# Turn off the annoying Microsoft Edge questions at first run.
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Type DWord

# Set hostname
echo "Set-ExecutionPolicy Unrestricted -Force" >> $installScriptPath
echo "" >> $installScriptPath
#echo "Start-Transcript -Append -Path `"$transcriptPath`"" >> $installScriptPath
#echo "" >> $installScriptPath
echo "`$hostname = `$env:COMPUTERNAME" >> $installScriptPath
echo "if ( `$hostname -ne `"${ud_machine_hostname}`" )" >> $installScriptPath
echo "{" >> $installScriptPath
echo "    Rename-Computer -NewName ${ud_machine_hostname}" >> $installScriptPath
echo "    Restart-Computer" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Install Forest/Domain
echo "`$domain = `$(Get-WmiObject -Class Win32_ComputerSystem).Domain" >> $installScriptPath
echo "if ( `$domain -ne `"${ud_domain}`" )" >> $installScriptPath
echo "{" >> $installScriptPath
echo "    try" >> $installScriptPath
echo "    {" >> $installScriptPath
echo "        Add-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools" >> $installScriptPath
echo "        Import-Module ADDSDeployment" >> $installScriptPath
echo "        `$dsrmPass = ConvertTo-SecureString `"${ud_domain_dsrm}`" -AsPlainText -Force" >> $installScriptPath
echo "        Install-ADDSForest -DomainName ${ud_domain} -DomainNetBiosName ${ud_domain_short} -InstallDNS:`$true -SafeModeAdministratorPassword `$dsrmPass -NoRebootOnCompletion -Force" >> $installScriptPath
echo "        Restart-Computer" >> $installScriptPath
echo "    } catch {" >> $installScriptPath
echo "        `"Should not occur.`"" >> $installScriptPath
echo "    }" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Install (self-signed) certificate and enable LDAPS
echo "`$certStoreLoc='HKLM:/Software/Microsoft/Cryptography/Services/NTDS/SystemCertificates/My/Certificates';" >> $installScriptPath
echo "if (!(Test-Path `$certStoreLoc)) {" >> $installScriptPath
echo "    `$domain = Get-ADDomain" >> $installScriptPath
echo "    `$domain_name = `$domain.DNSRoot" >> $installScriptPath
echo "    `$dns_name = `$env:computername + '.' + `$domain_name;" >> $installScriptPath
echo "    `$mycert=New-SelfSignedCertificate -DnsName `$dns_name -CertStoreLocation cert:/LocalMachine/My;" >> $installScriptPath
echo "    `$thumbprint=(`$mycert.Thumbprint | Out-String).Trim();" >> $installScriptPath
echo "    New-Item `$certStoreLoc -Force;" >> $installScriptPath
echo "    Copy-Item -Path HKLM:/Software/Microsoft/SystemCertificates/My/Certificates/`$thumbprint -Destination `$certStoreLoc;" >> $installScriptPath
echo "    Set-ADDomain -Identity ${ud_domain} -Replace @{`"ms-DS-MachineAccountQuota`"=`"100`"}" >> $installScriptPath
echo "    Start-Sleep -Seconds 300" >> $installScriptPath

# Adding several users to the Domain Admins group
echo "    net group `"Domain Admins`" ${ud_user_ldap_empty_pass_username} /add /Y" >> $installScriptPath
echo "    net group `"Domain Admins`" ${ud_user_kerberos_ticket_username} /add /Y" >> $installScriptPath
echo "    net group `"Domain Admins`" ${ud_user_lsass_da_username} /add /Y" >> $installScriptPath

# Setting the password of a certain user to be empty (blank). Requires -PasswordNotRequired flag to be set
echo "    Set-ADDefaultDomainPasswordPolicy -ComplexityEnabled `$false -Identity ${ud_domain}" >> $installScriptPath
echo "    Get-ADUser -Identity ${ud_user_ldap_empty_pass_username} | Set-ADUser -PasswordNotRequired `$true" >> $installScriptPath
echo "    net user ${ud_user_ldap_empty_pass_username} ```"```" /Y" >> $installScriptPath

# Setting the SPN of a user account for Kerberoasting attack
echo "    setspn -s HTTP/${ud_user_spn_username}.${ud_domain} ${ud_user_spn_username}" >> $installScriptPath

# Setting the SPN of machine account for Constrained Delegation
echo "    setspn -s ${ud_machine_spn_cd_type}/${ud_machine_spn_cd_destination} ${ud_machine_spn_cd_destination}" >> $installScriptPath
echo "    Get-ADComputer -Identity ${ud_machine_spn_cd_source} | Set-ADAccountControl -TrustedToAuthForDelegation `$true" >> $installScriptPath
echo "    Set-ADComputer -Identity ${ud_machine_spn_cd_source} -Add @{'msDS-AllowedToDelegateTo'=@('${ud_machine_spn_cd_type}/${ud_machine_spn_cd_destination}')}" >> $installScriptPath

# Enabling RBCD on a specific machine
echo "    `$front = Get-ADComputer -Identity ${ud_machine_rbcd_source}" >> $installScriptPath
echo "    `$back = Get-ADComputer -Identity ${ud_machine_rbcd_destination}" >> $installScriptPath
echo "    Set-ADComputer `$back -PrincipalsAllowedToDelegateToAccount `$front" >> $installScriptPath

echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Enable Unconstrained Delegation on specific machine
echo "`$compObj = Get-ADComputer -Identity ${ud_machine_unconstrained_delegation}" >> $installScriptPath  
echo "if (`$compObj) {" >> $installScriptPath
echo "    Get-ADComputer -Identity ${ud_machine_unconstrained_delegation} | Set-ADAccountControl -TrustedForDelegation `$true" >> $installScriptPath
echo "}" >> $installScriptPath

# Block AWS user-data endpoint
echo "New-NetFirewallRule -RemoteAddress 169.254.169.254 -RemotePort 80 -Protocol TCP -DisplayName `"Block User Data Location`" -Direction Outbound -Profile Any -Action Block" >> $installScriptPath

# Disable AV and Cloud-delivered security of Microsoft (catches Rubeus sometimes)
echo "Set-MpPreference -DisableRealtimeMonitoring `$true" >> $installScriptPath
echo "Set-MpPreference -MAPSReporting 0 -SubmitSamplesConsent 2 -CloudBlockLevel 0" >> $installScriptPath

# ScheduledTask to continuously load a Kerberos ticket into the DATA02 machine
echo "cd ${ud_download_location}" >> $installScriptPath
echo "`$URL = `"http://${ud_machine_portal_ip}/Rubeus.exe`"" >> $installScriptPath
echo "`$Destination = `"${ud_download_location}\Rubeus.exe`"" >> $installScriptPath
echo "Invoke-WebRequest -Uri `$URL -OutFile `$Destination" >> $installScriptPath
echo "" >> $installScriptPath

# Generate NT hash of adm_da account using Rubeus
echo "`$rubeusHash = .\Rubeus.exe hash /password:`"${ud_user_kerberos_ticket_pass}`"" >> $installScriptPath
echo "`$passwdRegex = `": ([A-F0-9]+)`"" >> $installScriptPath
echo "`$hash = `"`"" >> $installScriptPath
echo "`$rubeusHash -split `"``n`" | Where-Object { `$_.Trim() -ne `"`" } | ForEach-Object {" >> $installScriptPath
echo "    if (`$_ -match `$passwdRegex) {" >> $installScriptPath
echo "        `$hash = `$matches[1]" >> $installScriptPath
echo "    }" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Request TGT using Rubeus as adm_da. Extract generated ticket into Base64
echo "`$rubeusTicket = .\Rubeus.exe asktgt /domain:${ud_domain} /user:${ud_user_kerberos_ticket_username} /rc4:`$hash /nowrap" >> $installScriptPath
echo "`$ticketRegex = `"([A-Za-z0-9+/=]+)`"" >> $installScriptPath
echo "`$ticket = `"`"" >> $installScriptPath
echo "`$rubeusTicket -split `"``n`" | Where-Object { `$_.Trim() -ne `"`" } | ForEach-Object {" >> $installScriptPath
echo "    if (`$_ -match `$ticketRegex) {" >> $installScriptPath
echo "        if (`$matches[0] -like `"do*`") {" >> $installScriptPath
echo "            `$ticket = `$matches[0]" >> $installScriptPath
echo "        }" >> $installScriptPath
echo "    }" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Add DATA02 machine to trusted hosts
echo "Set-Item WSMan:\localhost\Client\TrustedHosts -Value `"${ud_machine_kerberos_hostname}`" -Force" >> $installScriptPath
echo "" >> $installScriptPath

# ScriptBlock to be executed on DATA02 machine. Adds a scheduled task that loads the Kerberos ticket into memory
echo "`$scriptBlock = {" >> $installScriptPath
echo "    param (`$ticket)" >> $installScriptPath
echo "    `$Source = `"C:\Users\Administrator`"" >> $installScriptPath
echo "    `$Destination = `"C:\Users\${ud_user_kerberos_ticket_username}`"" >> $installScriptPath
echo "    Copy-Item -Path `$Source -Destination `$Destination -Recurse -Force" >> $installScriptPath
echo "    cd ${ud_download_location}" >> $installScriptPath
echo "    `$URL = `"http://${ud_machine_portal_ip}/Rubeus.exe`"" >> $installScriptPath
echo "    `$Destination = `"${ud_download_location}\Rubeus.exe`"" >> $installScriptPath
echo "    Invoke-WebRequest -Uri `$URL -OutFile `$Destination" >> $installScriptPath
echo "    `$Trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay 00:00:30" >> $installScriptPath
echo "    `$Action = New-ScheduledTaskAction -Execute `"C:\Windows\System32\cmd.exe`" -Argument `"/K ${ud_download_location}\Rubeus.exe ptt /ticket:`$ticket`"" >> $installScriptPath
echo "    Register-ScheduledTask -Trigger `$Trigger -Action `$Action -User Administrator -Password `"${ud_machine_kerberos_local_admin_pass}`" -TaskName `"${ud_machine_kerberos_sched_task_name}`"" >> $installScriptPath
echo "    Start-ScheduledTask -TaskName `"${ud_machine_kerberos_sched_task_name}`"" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Use PsRemoting to execute ScriptBlock above on DATA02
echo "`$Username = `"WORKGROUP\Administrator`"" >> $installScriptPath
echo "`$Password = ConvertTo-SecureString `"${ud_machine_kerberos_local_admin_pass}`" -AsPlainText -Force" >> $installScriptPath
echo "`$Credential = New-Object System.Management.Automation.PSCredential (`$Username, `$Password)" >> $installScriptPath
echo "Invoke-Command -ComputerName `"${ud_machine_kerberos_hostname}`" -Credential `$Credential -Authentication Negotiate -ScriptBlock `$scriptBlock -ArgumentList `$ticket" >> $installScriptPath
echo "" >> $installScriptPath

# Delete Rubeus
echo "rm ${ud_download_location}\Rubeus.exe" >> $installScriptPath
echo "" >> $installScriptPath

# Unregister enrollment script
echo "Unregister-ScheduledTask -TaskName `"RollOut`" -Confirm:`$false" >> $installScriptPath
echo "Remove-Item -Path `"${ud_machine_install_script_path}`"" >> $installScriptPath

# New scheduled task
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
Register-ScheduledJob -Name RollOut -Trigger $trigger -FilePath $installScriptPath

# Remove user_data script from machine
$path = "C:\Windows\System32\config\systemprofile\AppData\Local\Temp"
$dir_name = Get-ChildItem -Path $path | Sort-Object | Select-Object -Last 1
$full_path = $path + "\" + $dir_name
Remove-Item -Path $full_path -Recurse -Force

Restart-Computer
</powershell>
