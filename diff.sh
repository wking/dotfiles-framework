#!/bin/bash
#
# Print diffs for each _FILE / ~/.FILE pair


# Create the diff between a pair of files
#
# handleFile( $file, $dotfile )
#
# Parameters:
# file - The file we're processing '_foo'
# dotfile - The file it should be linked to in ~/, e.g. '.foo'
function handleFile( )
{
    diff -ru $1 $2
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
