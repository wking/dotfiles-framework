#!/bin/bash
#
# Print diffs for each _FILE, ~/.FILE pair
#
# There are two modes, local and standard. In standard mode, we show the
# transition ~/.file -> _file, which shows the changes effected by
# `make override`.  In local mode we show the transition _file -> ~/.file,
# which shows the changes we need to apply to the .dotfiles to create
# your current local installation.  The --local option selects local mode.

LOCAL="no" # Select diff ordering

# parse options
while [ -n "$1" ]; do
    case "$1" in
	"--local")
	LOCAL="yes"
	;;
    esac
    shift
done

# Show the changes we'd apply on installation
#
# handleFile( $file, $dotfile )
#
# Parameters:
# file - The file we're processing '_foo'
# dotfile - The file it should be linked to in ~/, e.g. '.foo'
function handleFile( )
{
    if [ $LOCAL == "yes" ]; then
	diff -ru $2 $1
    else
	diff -ru $1 $2
    fi
}

# See if we can find any _files.
found=0
for i in _*; do
    if [ -e $i ]; then
        found=`expr $found + 1`
    fi
done

# If we found none then exit
if [ "$found" -lt 1 ]; then
    echo "WARNING: No files matching _* were found"
    exit
fi

# For each file in this directory.
for i in _*; do
    # Create .dotfile version.
    dotfile=.${i/_/}
    
    if [ ! -e ~/$dotfile ]; then
	echo "~/$dotfile doesn't exist"
    else
	# run the diff
        handleFile $i ~/$dotfile
    fi
done
