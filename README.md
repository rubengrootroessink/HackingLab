# Installation Instructions

## Generate SSH key pair
```
ssh-keygen [-t {TYPEOFKEY}]
```

## Copy your private SSH key to the Terraform folder
This is required as this key is necessary to upload some files to the gateway machine

## Change the following variables (in ```variables.tf```)
```
aws_access_key
aws_secret_key
aws_region (optional)
ssh_key_name (optional)
ssh_key_public_path (path to previously generated public key)
ssh_key_private_path (path to previously generated private key)
```

## Install and deploy AWS lab using Terraform
```
sudo apt get install terraform
terraform init (in the correct folder)
terraform apply
```

## Wait 20 minutes until the lab is deployed

## Login into the Wireguard server
```
ssh -i {private SSH key} ubuntu@{public IP address}
```

## Extract the file ```wireguard.conf``` and save it to your local machine as ```wg0.conf```
```
sudo wg-quick up ~/wg0.conf
```
