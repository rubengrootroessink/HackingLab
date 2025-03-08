<powershell>
Set-ExecutionPolicy unrestricted -Force

$installScriptPath = "${ud_machine_install_script_path}"
$transcriptPath = "${ud_machine_transcript_path}"
#Start-Transcript -Append -Path $transcriptPath

net user Administrator ${ud_machine_local_admin_pass}

# Turn off the annoying Microsoft Edge questions at first run.
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Type DWord

# Write username and password to a file on the user's desktop
echo "Web Application Server Credentials" >> ${ud_desktop_file_path}
echo "Username: ${ud_desktop_file_username}" >> ${ud_desktop_file_path}
echo "Password: ${ud_desktop_file_pass}" >> ${ud_desktop_file_path}

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
echo "    } catch {" >> $installScriptPath
echo "        `"Should not occur`"" >> $installScriptPath
echo "    }" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Enable WMI, disable Windows Defender and enable remote local administrator login
echo "if ( `$domain -eq `"${ud_domain}`" )" >> $installScriptPath
echo "{" >> $installScriptPath
echo "    netsh firewall set service RemoteAdmin enable" >> $installScriptPath
echo "    netsh advfirewall firewall set rule group=`"Windows Management Instrumentation (WMI)`" new enable=yes" >> $installScriptPath
echo "    netsh advfirewall firewall set rule group=`"Remote Administration`" new enable=yes" >> $installScriptPath
echo "    Set-MpPreference -DisableRealtimeMonitoring `$true" >> $installScriptPath

echo "    net localgroup Administrators `"${ud_domain}\${ud_admin_group}`" /add" >> $installScriptPath

# Block AWS user-data endpoint
echo "    New-NetFirewallRule -RemoteAddress 169.254.169.254 -RemotePort 80 -Protocol TCP -DisplayName `"Block User Data Location`" -Direction Outbound -Profile Any -Action Block" >> $installScriptPath

# Close if statement
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Unregister deployment script
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

Start-Sleep -Seconds 300
Restart-Computer
</powershell>
