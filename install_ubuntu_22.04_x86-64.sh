# PrintNode install setup for Raspberry pi 4 and Raspbian Bullseye aarch64
## Please run as root user

# Download PrintNode
echo "Downloading PrintNode"
wget https://dl.printnode.com/client/printnode/4.27.17/PrintNode-4.27.17-ubuntu-22.04-x86_64.tar.gz
echo "PrintNode downloaded"

# Create PrintNode directory in /usr/local
echo "Creating PrintNode directory in /usr/local"
mkdir /usr/local/PrintNode
echo "/usr/local/PrintNode created"

# Extract PrintNode in the PrintNode directory
echo "Extracting PrintNode in the PrintNode directory"
tar xf PrintNode-4.27.17-ubuntu-22.04-x86_64.tar.gz -C /usr/local/PrintNode --strip-components=1
echo "PrintNode extracted"

# Setup the autostart 
echo "Copying init.sh to /etc/init.d/PrintNode"
cd /usr/local/PrintNode
cp init.sh /etc/init.d/PrintNode
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
# Use sed to replace the placeholder with the actual client key
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

# Setup Zebra printer
echo "Setting up Zebra printer"
### Disabling the network search service
echo "Disabling the network search service"
systemctl stop cups-browsed.service
systemctl disable cups-browsed.service
echo "Network search service disabled"
### Deleting the existing drivers to avoid lpinfo -m timeout
echo "Deleting the existing drivers to avoid lpinfo -m timeout"
mdkir /usr/lib/cups/drivers/disable
mv /usr/lib/cups/drivers/* disable/
echo "Drivers deleted"
echo "You can install Zebra drivers manually safely now."

# Installing RustDesk
echo "Installing RustDesk"
## Get the latest version aarch64 deb from github and install it
wget https://github.com/rustdesk/rustdesk/releases/download/1.2.3-2/rustdesk-1.2.3-2-x86_64.deb
dpkg -i rustdesk-1.2.3-2-x86_64.deb
echo "RustDesk installed"

echo "Setup complete. Please setup your Zebra printer and RustDesk manually before restarting your Raspberry Pi."

