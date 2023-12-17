#!/bin/bash

userArg=""
if [ "$1" == "--user" ]; then
    userArg="--user"
    shift
fi

service=$1

if [ -z "$service" ]; then
    echo "Usage: systemctl-toggle.sh [--user] service"
    exit 1
fi

if systemctl "$userArg" is-active --quiet "$service"; then
    systemctl "$userArg" stop "$service"
else
    systemctl "$userArg" start "$service"
fi
