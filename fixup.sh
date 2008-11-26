#!/bin/bash
#
# Link each _FILE in the current directory to ~/.FILE
#
# Originally by Steve Kemp (http://www.steve.org.uk/)

FORCE="no" # If "yes", overwrite existing .files

# parse options
while [ -n "$1" ]; do
    case "$1" in
	"-f")
	FORCE="yes"
	;;
    esac
    shift
done

# Create the symbolic link.
#
# handleFile( $file, $dotfile )
#
# Parameters:
# file - The file we're processing '_foo'
# dotfile - The file it should be linked to in ~/, e.g. '.foo'
function handleFile( )
{
    file=$1
    dotfile=$2
    ln -s `pwd`/$file ~/$dotfile
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
    
    # If the file/directory exists and we're overriding it, remove it now
    if [ -e ~/$dotfile ] && [ $FORCE == "yes" ]; then
	rm -rvf ~/$dotfile
    fi
    
    # If this is a file.
    if [ -f $i ]; then
        
        # If it is a symlink, then remove it.
        if [ -h ~/$dotfile ]; then
            # Remove the old link, and create a new one.
            rm ~/$dotfile
        fi
        
        # It is a normal file.
        if [ -e ~/$dotfile ]; then
            echo "~/$dotfile exists - ignoring it."
        else
            # File doesn't exist, create the link.
            handleFile $i $dotfile
        fi
    else
        # The file _foo is a directory.
        
        # If that directory doesn't exist in ~/ then create it.
        if [ ! -d ~/$dotfile ]; then
            echo "Creating new directory in ~";
            mkdir ~/$dotfile
        fi
       
        # Now link all non-linked files up.
        for s in $i/*; do
            file=`basename $s`
       
            if [ ! -h ~/$dotfile/$file ]; then
                ln -s `pwd`/$s ~/$dotfile/$file
            fi
        done
    fi
done
