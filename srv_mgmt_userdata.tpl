<powershell>
Set-ExecutionPolicy unrestricted -Force

$installScriptPath = "${ud_machine_install_script_path}"
$transcriptPath = "${ud_machine_transcript_path}"
$scheduledTaskUserPath = "${ud_machine_sched_task_lsass_user_path}"
$scheduledTaskDAPath = "${ud_machine_sched_task_lsass_da_path}"
Start-Transcript -Append -Path $transcriptPath

net user Administrator ${ud_machine_local_admin_pass}

# Set hostname
echo "Set-ExecutionPolicy Unrestricted -Force" >> $installScriptPath
echo "" >> $installScriptPath
echo "Start-Transcript -Append -Path `"$transcriptPath`"" >> $installScriptPath
echo "" >> $installScriptPath
echo "`$hostname = `$env:COMPUTERNAME" >> $installScriptPath
echo "if ( `$hostname -ne `"${ud_machine_hostname}`" )" >> $installScriptPath
echo "{" >> $installScriptPath
echo "    Rename-Computer -NewName ${ud_machine_hostname}" >> $installScriptPath
echo "    Restart-Computer" >> $installScriptPath
echo "}" >> $installScriptPath
echo "" >> $installScriptPath

# Enable WMI, disable Windows Defender and enable remote local administrator login
echo "netsh firewall set service RemoteAdmin enable" >> $installScriptPath
echo "netsh advfirewall firewall set rule group=`"Windows Management Instrumentation (WMI)`" new enable=yes" >> $installScriptPath
echo "netsh advfirewall firewall set rule group=`"Remote Administration`" new enable=yes" >> $installScriptPath
echo "Set-MpPreference -DisableRealtimeMonitoring `$true" >> $installScriptPath

# Starts ScheduledJobs to perform remote logons via RDP to machines
echo "if( (Get-ScheduledJob).Count -eq 1 ) {" >> $installScriptPath
echo "    Invoke-WebRequest https://github.com/jakobfriedl/precompiled-binaries/raw/refs/heads/main/LateralMovement/SharpRDP.exe -OutFile C:\Windows\Temp\SharpRDP.exe" >> $installScriptPath
echo "    `$sTrigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30" >> $installScriptPath
echo "    `$timeSpan = New-TimeSpan -Minutes 5" >> $installScriptPath
echo "    Register-ScheduledJob -Name ${ud_machine_sched_task_lsass_user_name} -Trigger `$sTrigger -RunEvery `$timeSpan -RunNow -FilePath $scheduledTaskUserPath" >> $installScriptPath
echo "    Register-ScheduledJob -Name ${ud_machine_sched_task_lsass_da_name} -Trigger `$sTrigger -RunEvery `$timeSpan -RunNow -FilePath $scheduledTaskDAPath" >> $installScriptPath
echo "    Restart-Computer" >> $installScriptPath
echo "}" >> $installScriptPath

echo "C:\Windows\Temp\SharpRDP.exe computername=${ud_ms_smb_ip} command=calc.exe username=${ud_domain}\${ud_ms_smb_username} password=${ud_ms_smb_pass}" >> $scheduledTaskUserPath
echo "C:\Windows\Temp\SharpRDP.exe computername=${ud_ms_lsass_da_ip} command=calc.exe username=${ud_domain}\${ud_ms_lsass_da_username} password=${ud_ms_lsass_da_pass}" >> $scheduledTaskDAPath

# New scheduled task
$trigger = New-JobTrigger -AtStartup -RandomDelay 00:00:30
Register-ScheduledJob -Name RollOut -Trigger $trigger -FilePath $installScriptPath

Start-Sleep -Seconds 600
Restart-Computer
</powershell>
