#!/bin/sh
#
# .xinitrc, a startup file for X

if [ -n $(which conky) ]; then
    conky &
fi

# Setup ACPI on my ASUS EEPC
if [ -e /usr/bin/asus_acpid ]; then
    ASUS_ACPID=$(ps -u $(whoami) | grep asus_acpid)
    if [ "$ASUS_ACPID" == "" ]; then
        /usr/bin/asus_acpid --logfile /tmp/asus_acpid.log &
    fi
fi

# Set up keybindings
xmodmap ~/.Xmodmap

exec startfluxbox
