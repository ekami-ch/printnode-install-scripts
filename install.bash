#!/bin/bash
# PrintNode install setup for Raspberry pi 4 and Raspbian Bullseye aarch64
## Please run as root user
# Check if this script is being run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# 3 arguments:
#  - architecture
#  - distribution
#  - PrintNode API key

# Usage:
# ./install.bash <architecture> <distribution> <PrintNode client key>
echo "PrintNode Setup"
echo "Checking the arguments"
if [ $# -ne 3 ]; then
  echo "Invalid number of arguments. Usage: ./install.bash <architecture> <distribution> <PrintNode API key>"
  exit 1
fi

# PrintNode architecture
architecture=$1
# PrintNode distribution
distribution=$2
# PrintNode API key
api_key=$3


# Declare an associative array to hold the download links
declare -A printnode_links
printnode_links["aarch64,pi-bullseye"]="https://dl.printnode.com/client/printnode/4.27.8/PrintNode-4.27.8-pi-bullseye-aarch64.tar.gz"
printnode_links["aarch64,pi-bookworm"]="https://dl.printnode.com/client/printnode/4.27.8/PrintNode-4.27.8-pi-bullseye-aarch64.tar.gz"
printnode_links["x86_64,ubuntu-22.04"]="https://dl.printnode.com/client/printnode/4.27.17/PrintNode-4.27.17-ubuntu-22.04-x86_64.tar.gz"

# Check if the provided architecture and distribution are valid
printnode_edition="${architecture},${distribution}"
if [ -z "${printnode_links[$printnode_edition]}" ]; then
    echo "Invalid architecture or distribution. Valid combinations are:"
    for k in "${!printnode_links[@]}"; do
        echo " - $k"
    done
    exit 1
fi

# PrintNode download link
printnode_link=${printnode_links[$printnode_edition]}

echo "Download link: $printnode_link"

# Execute the curl command with an empty password and store its output in a variable
echo "Getting the client key from PrintNode API"


# Making the API call and storing the result along with the HTTP status code
response=$(curl -s -w "\n%{http_code}" "https://api.printnode.com/client/key/0?version=4.7.1&edition=printnode" -u "$api_key:")
client_key=$(echo "$response" | head -n -1)
http_status=$(echo "$response" | tail -n 1)

# Check if the curl command succeeded and valid HTTP status code received
if [ "$http_status" -ne 200 ]; then
    echo "Failed to retrieve client key due to a network or server error. Status code: $http_status"
    echo "Response was: $client_key"
    exit 1
fi

# Simple error handling with grep
if echo "$client_key" | grep -q "API Key not found"; then
    echo "API Key error: $client_key"
    exit 1
fi

# Assume key retrieval was successful if no errors were found
echo "Client key successfully retrieved: $client_key"

# Remove quotes from the client_key variable
echo "Removing quotes from the client key"
client_key=$(echo "$client_key" | tr -d '"')
echo "Client key quotes removed: $client_key"

# Verify that client_key is not empty and does not contain only spaces
if [[ -z $client_key || $client_key =~ ^[[:space:]]*$ ]]; then
    echo "No client key was retrieved, or the key is invalid."
    exit 1
else
    echo "Client key successfully retrieved and validated."
fi



# PrintNode Setup
echo "Setting up PrintNode"
## Specific dependencies for printnode_edition
case $printnode_edition in
    aarch64,pi-bookworm)
        ## Installing missing dependencies
        echo "Installing missing dependencies"
        echo "Installing libssl1.1"
        apt-get install -y libssl1.1
        echo "libssl1.1 installed"
        echo "Missing dependencies installed"
        ;;
esac


## Download PrintNode
echo "Downloading PrintNode"
# If temp file exists, remove it
if [ -f /tmp/printnode.tar.gz ]; then
    rm -f /tmp/printnode.tar.gz
fi 

wget $printnode_link -O /tmp/printnode.tar.gz
echo "PrintNode downloaded"

## Create PrintNode directory in /usr/local
echo "Creating PrintNode directory in /usr/local"
mkdir /usr/local/PrintNode
echo "/usr/local/PrintNode created"

## Extract PrintNode in the PrintNode directory
echo "Extracting PrintNode in the PrintNode directory"
tar xf /tmp/printnode.tar.gz -C /usr/local/PrintNode --strip-components=1
echo "PrintNode extracted"

## Setup the autostart 
echo "Copying init.sh to /etc/init.d/PrintNode"
cp /usr/local/PrintNode/init.sh /etc/init.d/PrintNode
echo "init.sh copied to /etc/init.d/PrintNode"


### Add the curl result to the /etc/init.d/PrintNode script at the line cmd="/usr/local/PrintNode/PrintNode --headless --shutdown-on-sigint --web-interface --remove-scales-support"
echo "Adding the key to /etc/init.d/PrintNode"
### Use sed to replace the placeholder with the actual client key
echo "Adding key to /etc/init.d/PrintNode"
sed -i 's@\(cmd="/usr/local/PrintNode/PrintNode --headless --shutdown-on-sigint --web-interface --remove-scales-support\).*@\1'" --client-key=$client_key\""'@' /etc/init.d/PrintNode
echo "Key added to /etc/init.d/PrintNode"
## Add the lines:
##printf "%s" "Waiting for api.printnode.com ..."
##while ! ping -c 1 -n -w 1 api.printnode.com >/dev/null 2>&1
##do
##    printf "%c" "."
##    sleep 1s
##done
## After the "cd $dir" line in the /etc/init.d/PrintNode script
echo "Adding the lines to wait for api.printnode.com in /etc/init.d/PrintNode"
sed -i '/cd "\$dir"/a \
printf "%s" "Waiting for api.printnode.com ..." \
while ! ping -c 1 -n -w 1 api.printnode.com >/dev/null 2>&1 \
do \
    printf "%c" "." \
    sleep 1s \
done \
printf "\n%s\n"  "Server api.printnode.com is online"' /etc/init.d/PrintNode
echo "Lines added to /etc/init.d/PrintNode"
## Auto start PrintNode
echo "Setting up PrintNode to autostart"
sudo update-rc.d PrintNode defaults
echo "PrintNode autostart done"
echo "PrintNode Setup complete"

# Setup printer drivers
echo "Setting up printer drivers"
### Disabling the network search service
echo "Disabling the network search service"
systemctl stop cups-browsed.service
systemctl disable cups-browsed.service
echo "Network search service disabled"
### Deleting the existing drivers to avoid lpinfo -m timeout
echo "Deleting the existing printer drivers to avoid lpinfo -m timeout"
mkdir /usr/lib/cups/disable
mv /usr/lib/cups/driver/* /usr/lib/cups/disable/
echo "Drivers deleted"
echo "You can install printer drivers manually safely now."

# Cleanup
echo "Cleaning up"
rm /tmp/printnode.tar.gz
echo "Cleanup complete"

echo "Setup complete. Please setup your printers and RustDesk manually before restarting your Raspberry Pi."

