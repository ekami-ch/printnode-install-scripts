#!/bin/bash
# PrintNode install setup for Raspberry pi 4 and Raspbian Bullseye aarch64
## Please run as root user
# Check if this script is being run as root
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# PrintNode download links
printnode_links=(
  https://dl.printnode.com/client/printnode/4.27.8/PrintNode-4.27.8-pi-bullseye-aarch64.tar.gz
  https://dl.printnode.com/client/printnode/4.27.8/PrintNode-4.27.8-pi-bullseye-aarch64.tar.gz
  https://dl.printnode.com/client/printnode/4.27.17/PrintNode-4.27.17-ubuntu-22.04-x86_64.tar.gz
)

# PrintNode package names
printnode_packages=(
  PrintNode-4.27.8-pi-bullseye-aarch64.tar.gz
  PrintNode-4.27.8-pi-bullseye-aarch64.tar.gz
  PrintNode-4.27.17-ubuntu-22.04-x86_64.tar.gz
)

printnode_editions=(
  pi-bullseye-aarch64
  pi-bookworm-aarch64
  ubuntu-22.04-x86_64
)

# Menu 
echo "PrintNode Setup Menu"
echo "What do you want to do?"
echo "1. Install PrintNode for Raspbian Bullseye aarch64 (Raspberry pi 4 & 4B)"
echo "2. Install PrintNode for Raspbian Bookworm aarch64 (Raspberry pi 5)"
echo "3. Install PrintNode for Ubuntu 22.04 LTS AMD64"
echo "4. Exit"
read -p "Enter your choice [1-4]: " choice

# Switch case to set printnode_link and printnode_package
case $choice in
    1)
        printnode_link=${printnode_links[0]}
        printnode_package=${printnode_packages[0]}
        printnode_edition=${printnode_editions[0]}
        ;;
    2)
        printnode_link=${printnode_links[1]}
        printnode_package=${printnode_packages[1]}
        printnode_edition=${printnode_editions[1]}
        ;;
    3)
        printnode_link=${printnode_links[2]}
        printnode_package=${printnode_packages[2]}
        printnode_edition=${printnode_editions[2]}
        ;;
    4)
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid choice. Please enter a number between 1 and 4."
        exit 1
        ;;
esac

echo "Selected PrintNode Edition: $printnode_edition"
sleep 2

# PrintNode Setup
echo "Setting up PrintNode"
## Switch case printnode_edition
case $printnode_edition in
    pi-bullseye-aarch64)
        ;;
    pi-bookworm-aarch64)
        ## Installing missing dependencies
        echo "Installing missing dependencies"
        echo "Installing libssl1.1"
        apt-get install libssl1.1
        echo "libssl1.1 installed"
        echo "Missing dependencies installed"
        ;;
    ubuntu-22.04-x86_64)
        ;;
    *) 
        echo "Invalid PrintNode Edition. Exiting..."
        exit 1
        ;;
esac
## Download PrintNode
echo "Downloading PrintNode"
wget $printnode_link
echo "PrintNode downloaded"
## Create PrintNode directory in /usr/local
echo "Creating PrintNode directory in /usr/local"
mkdir /usr/local/PrintNode
echo "/usr/local/PrintNode created"
## Extract PrintNode in the PrintNode directory
echo "Extracting PrintNode in the PrintNode directory"
tar xf $printnode_package -C /usr/local/PrintNode --strip-components=1
echo "PrintNode extracted"
## Setup the autostart 
echo "Copying init.sh to /etc/init.d/PrintNode"
cp /usr/local/PrintNode/init.sh /etc/init.d/PrintNode
echo "init.sh copied to /etc/init.d/PrintNode"
## Ask the user input for a printnode api key. Show them the api key and ask if it is correct, if not ask them again.
read -p "Enter your PrintNode API key: " api_key
### try to curl "https://api.printnode.com/client/key/0?version=4.7.1&edition=printnode" -u XXXX_API_KEY_XXXX, if it fails ask them again
### if it succeeds break the loop
while true; do
    echo "Checking the API key"
    if curl "https://api.printnode.com/client/key/0?version=4.7.1&edition=printnode" -u $api_key:''; then
        echo "API key is correct"
        break
    else
        echo "API key is incorrect"
        read -p "Enter your PrintNode API key: " api_key
    fi
done
### Add the curl result to the /etc/init.d/PrintNode script at the line cmd="/usr/local/PrintNode/PrintNode --headless --shutdown-on-sigint --web-interface --remove-scales-support"
echo "Adding the key to /etc/init.d/PrintNode"
### Execute the curl command with an empty password and store its output in a variable
echo "Getting the client key"
client_key=$(curl -s "https://api.printnode.com/client/key/0?version=4.7.1&edition=printnode" -u $api_key:)
echo "Client key retrieved"
### Remove quotes from the client_key variable
echo "Removing quotes from the client key"
client_key=$(echo $client_key | tr -d '"')
echo "Client key quotes removed"
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
rm $printnode_package
echo "Cleanup complete"

echo "Setup complete. Please setup your printers and RustDesk manually before restarting your Raspberry Pi."

