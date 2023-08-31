#!/bin/bash

if [ -z "$1" ]; then
    echo "Error: No hostname specified"
    exit 1
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sudo scutil --set HostName "$1"
    sudo scutil --set LocalHostName "$1"
    dscacheutil -flushcache

elif [ -d "/run/systemd/system" ]; then
    # Linux with systemd
    sudo hostnamectl set-hostname "$1"

elif grep -q Microsoft /proc/version; then
    # WSL2
    if grep -q "hostname\s*=" /etc/wsl.conf; then
        sudo sed -i "s/hostname\s*=.*/hostname = $1/g" /etc/wsl.conf
    elif grep -q "\[network\]" /etc/wsl.conf; then
        sudo sed -i "s/\[network\]/\[network\]\nhostname = $1/g" /etc/wsl.conf
    else
        echo "[network]" | sudo tee /etc/wsl.conf >/dev/null
        echo "hostname = $1" | sudo tee -a /etc/wsl.conf >/dev/null
    fi
    echo "Please restart WSL2 for the changes to take effect."
    echo "Run 'wsl --shutdown' from PowerShell or CMD and then reopen your terminal."

elif [ -f "/etc/hostname" ]; then
    echo "$1" | sudo tee /etc/hostname >/dev/null

else
    echo "Error: Unsupported system"
    exit 1
fi