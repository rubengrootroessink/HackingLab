<powershell>
Set-ExecutionPolicy unrestricted -Force

$installScriptPath = "${ud_machine_install_script_path}"
$transcriptPath = "${ud_machine_transcript_path}"
$caScriptPath = "${ud_sched_task_path}" # TODO, remove?
#Start-Transcript -Append -Path $transcriptPath

net user Administrator ${ud_machine_local_admin_pass}

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
echo "`$domain" >> $installScriptPath
echo "if ( `$domain -ne `"${ud_domain}`" )" >> $installScriptPath
echo "{" >> $installScriptPath
echo "    try" >> $installScriptPath
echo "    {" >> $installScriptPath
echo "        `$domain_username = `"${ud_domain}\${ud_user_domain_join_username}`"" >> $installScriptPath
echo "        `$domain_password = ConvertTo-SecureString `"${ud_user_domain_join_pass}`" -AsPlainText -Force" >> $installScriptPath
echo "        `$credential = New-Object System.Management.Automation.PSCredential(`$domain_username, `$domain_password)" >> $installScriptPath
echo "        Add-Computer -DomainName ${ud_domain} -Credential `$credential -Passthru -Verbose -Force -Restart" >> $installScriptPath
echo "        Restart-Computer" >> $installScriptPath
echo "    }" >> $installScriptPath
echo "    catch" >> $installScriptPath
echo "    {" >> $installScriptPath
echo "        echo 'Done'" >> $installScriptPath
echo "    }" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Enable WMI, disable Windows Defender and enable remote local administrator login
echo "`$task = Get-ScheduledTask -TaskName `"${ud_sched_task_name}`" -ErrorAction SilentlyContinue" >> $installScriptPath
echo "if ( -not `$task )" >> $installScriptPath
echo "{" >> $installScriptPath
echo "    netsh firewall set service RemoteAdmin enable" >> $installScriptPath
echo "    netsh advfirewall firewall set rule group=`"Windows Management Instrumentation (WMI)`" new enable=yes" >> $installScriptPath
echo "    netsh advfirewall firewall set rule group=`"Remote Administration`" new enable=yes" >> $installScriptPath
echo "    Set-MpPreference -DisableRealtimeMonitoring `$true" >> $installScriptPath
echo "" >> $installScriptPath

# Block AWS user-data endpoint
echo "    New-NetFirewallRule -RemoteAddress 169.254.169.254 -RemotePort 80 -Protocol TCP -DisplayName `"Block User Data Location`" -Direction Outbound -Profile Any -Action Block" >> $installScriptPath
echo "" >> $installScriptPath

echo "    `$username = `"${ud_domain}\${ud_sched_task_username}`"" >> $installScriptPath
echo "    `$password = `"${ud_sched_task_pass}`"" >> $installScriptPath
echo "    `$action = New-ScheduledTaskAction -Execute `"powershell.exe`" -Argument `"-NoProfile -File $caScriptPath`"" >> $installScriptPath
echo "    `$trigger = New-ScheduledTaskTrigger -AtStartup -RandomDelay 00:00:30" >> $installScriptPath
echo "    Register-ScheduledTask -TaskName `"${ud_sched_task_name}`" -Action `$action -Trigger `$trigger -User `$username -Password `$password -RunLevel Highest" >> $installScriptPath
echo "    Restart-Computer" >> $installScriptPath
echo "" >> $installScriptPath
echo "}" >> $installScriptPath

echo "if (!(Test-Path `"HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc`")) {" >> $installScriptPath
echo "    Start-Sleep 60" >> $installScriptPath # TODO
echo "    Restart-Computer" >> $installScriptPath
echo "} else {" >> $installScriptPath

# Unregister enrollment script
echo "    Unregister-ScheduledTask -TaskName `"RollOut`" -Confirm:`$false" >> $installScriptPath
echo "    Remove-Item -Path `"${ud_machine_install_script_path}`"" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

echo "Start-Transcript -Append -Path `"$transcriptPath`"" >> $caScriptPath
echo "Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools" >> $caScriptPath
echo "Install-WindowsFeature ADCS-Web-Enrollment -IncludeManagementTools" >> $caScriptPath
echo "Install-WindowsFeature RSAT-ADCS-Mgmt -IncludeManagementTools" >> $caScriptPath
echo "Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -KeyLength 2048 -HashAlgorithm SHA256 -CryptoProviderName `"RSA#Microsoft Software Key Storage Provider`" -Force" >> $caScriptPath
echo "Restart-Service CertSvc" >> $caScriptPath
echo "Install-AdcsWebEnrollment -Force" >> $caScriptPath
echo "iisreset" >> $caScriptPath

# New scheduled task
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
Register-ScheduledJob -Name RollOut -Trigger $trigger -FilePath $installScriptPath

# Remove user_data script from machine
$path = "C:\Windows\System32\config\systemprofile\AppData\Local\Temp"
$dir_name = Get-ChildItem -Path $path | Sort-Object | Select-Object -Last 1
$full_path = $path + "\" + $dir_name
Remove-Item -Path $full_path -Recurse -Force

Start-Sleep -Seconds 300
Restart-Computer
</powershell>
