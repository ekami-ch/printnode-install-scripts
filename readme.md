# PrintNode Install Scripts

This repository contains the scripts to install PrintNode client on some Raspberry Pi OS and Ubuntu 22.04 LTS.

It install printnode client automatically and configure it to start at boot.
It also install the necessary dependencies to make it work on some Raspberry Pi OS.

This script also remove local printer drivers and auto-discovery of printers, as it is breaking the cups server on Raspberry Pi OS (error : **driver not found: 'Success'**)

## Usage
To use the script, download the script and run it with the following command:
```bash
sudo ./install.bash <architecture> <distribution> <api key>
```

**Architecture possible values** : 
- aarch64 
- x86_64

**Distribution possible values** :
- pi-bullseye
- pi-bookworm
- ubuntu-22.04

**Possible Combination** :
- aarch64 pi-bullseye
- aarch64 pi-bookworm
- x86_64 ubuntu-22.04

**API Key** : Your PrintNode API Key

## Pi Bookworm (Pi 5)
This script is for the Raspberry Pi OS Bookworm for Raspberry Pi 5.
It uses the PrintNode client from Raspberry Pi OS Bullseye (Pi 4), and add the missing dependency package to make it work on pi 5.

### Requirements 
- Hardware : Raspberry Pi 5
- OS : Raspberry Pi OS Bookworm Aarch64

## Pi Bullseye (Pi 4 & 4B)
This script is for the Raspberry Pi OS Bullseye for Raspberry Pi 4. 

### Requirements
- Hardware : Raspberry Pi 4 & Pi 4B
- OS : Raspberry Pi OS Bullseye Aarch64

## Ubuntu 22.04 LTS
This script is for system on Ubuntu 22.04 LTS.

### Requirements
- Hardware : Any X86_64 compatible hardware
- OS : Ubuntu 22.04 LTS AMD64

