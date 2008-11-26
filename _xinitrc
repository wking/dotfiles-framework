#!/bin/bash
# .xinitrc startup file for X

#WM="gnome"
#WM="twm"
#WM="fluxbox"
WM="Find installed"

# Set up keybindings
xmodmap .Xinitrc

# xrdb -load $HOME/.Xresources

if [ "$WM" == "Find installed" ]
then
    for M in fluxbox gnome-session twm
    do
	PATH=`which $M`
	if [ -n "$PATH" ]
	then
	    if [ "$M" == "fluxbox" ] || [ "$M" == "twm" ; then
		WM="$M"
	    elif [ "$M" == "gnome-session" ]
		WM="gnome"
	    else
		echo "No known windows manager installed"
		exit
	    fi
	fi
    done
fi

if [ "$WM" == "twm" ] # tabbed windows manager.  Very simple.
then
 # starts a clock, several terminals, and leaves the window manager running 
 # as the last application.   Assuming that the window manager has been 
 # configured properly, the user then chooses the Exit menu item to 
 # shut down X.
 xsetroot -solid darkgray &
 xclock -g 50x50-0+0 -bw 0 &
 xload -g 200x50-50+0 -bw 0 -bg black -fg white &
 # alias xterm='xterm -bg black -fg white'
 xterm -bg black -fg white -g 80x39+0+0 &
 xterm -bg black -fg white -g 80x35+0-0 &
 xterm -bg black -fg white -g 80x76-0+0 &
 twm
elif [ "$WM" == "gnome" ]
 then
 # start dbus session for gnome power manager
 eval `dbus-launch --auto-syntax`
 xterm -bg black -fg white -g 80x39+0+0 &
 gnome-session
elif [ "$WM" == "fluxbox" ]
 then
 xterm -bg black -fg white -g 80x39+0+0 &
 fluxbox
fi
