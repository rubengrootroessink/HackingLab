#!/bin/bash
sudo apt update -y # Update links to package repo
sudo apt -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade -y # Upgrade all packages, always keep locally modified versions
sudo apt install wireguard -y
sudo apt install unzip -y

mkdir wireguard_keys

wg genkey > ./wireguard_keys/client.key
wg pubkey < ./wireguard_keys/client.key > ./wireguard_keys/client.pub

wg genkey > ./wireguard_keys/server.key
wg pubkey < ./wireguard_keys/server.key > ./wireguard_keys/server.pub

server_key=$(cat ./wireguard_keys/server.key | tr -d '\n')
server_pub=$(cat ./wireguard_keys/server.pub | tr -d '\n')
client_key=$(cat ./wireguard_keys/client.key | tr -d '\n')
client_pub=$(cat ./wireguard_keys/client.pub | tr -d '\n')

conf_file="${ud_network_wireguard_server_config_location}"

echo "[Interface]" >> $conf_file
echo "PrivateKey = $server_key" >> $conf_file
echo "Address = ${ud_network_wireguard_server_ip}/32" >> $conf_file
echo "ListenPort = ${ud_network_wireguard_server_port}" >> $conf_file
echo "PreUp = sysctl -w net.ipv4.ip_forward=1" >> $conf_file
echo "" >> $conf_file

echo "[Peer]" >> $conf_file
echo "PublicKey = $client_pub" >> $conf_file
echo "AllowedIPs = ${ud_network_wireguard_client_ip}/32" >> $conf_file
echo "" >> $conf_file

client_file="${ud_network_wireguard_client_config_location}"
external_ip=$(curl ifconfig.me)

echo "[Interface]" >> $client_file
echo "PrivateKey = $client_key" >> $client_file
echo "Address = ${ud_network_wireguard_client_ip}/32" >> $client_file
echo "ListenPort = ${ud_network_wireguard_client_port}" >> $client_file
echo "PostUp = ping -c1 ${ud_domain_controller_ip}" >> $client_file
echo "" >> $client_file

echo "[Peer]" >> $client_file
echo "PublicKey = $server_pub" >> $client_file
echo "Endpoint = $external_ip:${ud_network_wireguard_server_port}" >> $client_file
echo "AllowedIPs = ${ud_network_subnet_cidr}" >> $client_file
echo "PersistentKeepalive = 25" >> $client_file

systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service

folder="${ud_downloads_location}"
user="${ud_downloads_owner}:${ud_downloads_owner}"

mkdir -p $folder
mv $folder/../Rubeus.exe $folder/Rubeus.exe
mv $folder/../SpoolSample.exe $folder/SpoolSample.exe
wget https://live.sysinternals.com/PsExec64.exe -O $folder/PsExec64.exe
wget https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20220919/mimikatz_trunk.zip -O $folder/mimikatz_trunk.zip
unzip $folder/mimikatz_trunk.zip -d $folder/mimikatz
rm $folder/mimikatz_trunk.zip

echo "Hint: Use Responder on your local machine!" >> $folder/Readme.txt
echo "" >> $folder/Readme.txt
echo "The following tools are useful throughout the lab" >> $folder/Readme.txt
echo "- Responder:" >> $folder/Readme.txt
echo "  sudo apt install python3-netifaces" >> $folder/Readme.txt
echo "  git clone https://github.com/lgandx/Responder.git" >> $folder/Readme.txt
echo "- Netexec:" >> $folder/Readme.txt
echo "  sudo apt install netexec" >> $folder/Readme.txt
echo "- Impacket (wmiexec/ntlmrelayx/ldapdomaindump/psexec):" >> $folder/Readme.txt
echo "  sudo apt install python3-impacket" >> $folder/Readme.txt

chown -R $user $folder

cd $folder && sudo python3 -m http.server 80
