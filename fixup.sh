#!/bin/bash
#
# Link each _FILE in the current directory to ~/.FILE
#
# Originally by Steve Kemp (http://www.steve.org.uk/)
#
# By default, fixup only replaces missing files and simlinks.  You can
# optionally overwrite any local files and directories by passing the
# --force option.

FORCE="no"   # If "yes", overwrite existing .files
DRY_RUN="no" # If "yes", disable any actions that change the filesystem

# parse options
while [ -n "$1" ]; do
    case "$1" in
	"--force")
	FORCE="yes"
	;;
	"--dry-run")
	DRY_RUN="yes"
	;;
    esac
    shift
done

# Create the symbolic link.
#
# linkFiles( $file, $dotfile )
#
# Parameters:
# file - The file we're processing '_foo'
# dotfile - The file it should be linked to in ~/, e.g. '.foo'
function linkFiles ( )
{
    file=$1
    dotfile=$2
    ln -s `pwd`/$file ~/$dotfile
}

# Check if a file is patch controlled
#
# isPatchFile( $file, $patchfiles)
#
# Parameters:
# file - The file we're processing '_foo'
# patchfiles - A string list of patchfiles
function isPatchFile( )
{
    file=$1
    shift
    patchfiles=$*
    
    for patchfile in $patchfiles; do
	if [ $file == $patchfile ]; then
	    return 0
	fi
    done    
    return 1
}

# Check if a file is controlled by the dotfiles framework
#
# isControlledFile( $file, $patchfiles )
#
# Parameters:
# file - The file we're processing '_foo'
# patchfiles - A string list of patchfiles
function isControlledFile( )
{
    file=$1
    shift
    patchfiles=$*
    dotfile=.${file/_/}
    
    if [ ! -e ~/$dotfile ]; then
	#echo "~/$dotfile is controlled (does not exist)"
	return 0
    elif [ -h ~/$dotfile ]; then
	#echo "~/$dotfile is controlled (a symlink)"
	return 0
    elif isPatchFile $file $patchfiles; then
	#echo "~/$dotfile is controlled (a patchfile)"
	return 0
    fi    
    #echo "~/$dotfile is not controlled"
    return 1
}

# Check if the installed file matches the dotfiles version
#
# fileChanged( $file, $dotfile )
#
# Parameters:
# file - The file we're processing '_foo'
# dotfile - The file it should be linked to in ~/, e.g. '.foo'
function fileChanged()
{
    file=$1
    dotfile=$2
    DIFF=`diff -r ~/$dotfile $file`
    [ -z "$DIFF" ]
    return $?
}

# Prettyprint a list of files
#
# listFiles( $title, $list )
#
# Parameters:
# title - The name of the list
# list - The files in the list
function listFiles()
{
    title=$1
    shift
    files=$*
    if [ $# -gt 0 ]; then
	echo "$title: ($#)"
	for file in $files; do
	    echo "  $file"
	done
    fi
}


# See if we can find any _files.
found=0
for file in _*; do
    if [ -e $file ]; then
        found=`expr $found + 1`
    fi
done

# If we found none then exit
if [ "$found" -lt 1 ]; then
    echo "WARNING: No files matching _* were found"
    exit
fi

# If a local.patch file exists, apply it's changes to our dotfiles
# files.  We catch the output of this to get a list of the files under
# local.patch control
if [ -f "local.patch" ]; then
    patchoption=""
    if [ $DRY_RUN == "yes" ]; then
	patchoption="--dry-run"
    fi
    echo "\$ patch $patchoption -i local.patch"
    patchout=`patch $patchoption -i local.patch || exit 1`
    echo "$patchout"
    echo ""
    # e.g. patchout:
    # patching file _emacs
    # patching file _gnuplot
    PATCHFILES=`echo "$patchout" | sed -n 's/patching file //p'`
    #listFiles "Patched files" $PATCHFILES
fi

IGNORED=""
NOT_CHANGED=""
UPDATED=""
ADDED=""

# For each file in this directory.
for file in _*; do
    # Create .dotfile version.
    dotfile=.${file/_/}
    
    # Decide what to do with files we don't normally control
    OVERRIDDEN="no"
    if ! isControlledFile $file $PATCHFILES; then
	if [ $FORCE == "yes" ]; then
	    OVERRIDDEN="yes"
	    UPDATED="$UPDATED ~/$dotfile"
	    if [ $DRY_RUN == "no" ]; then
                # Back up the ~/$dotfile
		mv ~/$dotfile ~/$dotfile.bak
	    fi
	else
	    IGNORED="$IGNORED ~/$dotfile"
	    continue
	fi
    fi

    # Targets getting to this point should be controlled
    if [ -e ~/$dotfile ]; then
	# The target exists, see if it has changed
	if fileChanged $file $dotfile; then
	    NOT_CHANGED="$NOT_CHANGED ~/$dotfile"
	    continue
	else
	    if [ $OVERRIDDEN == "no" ]; then
		UPDATED="$UPDATED ~/$dotfile"
	    fi
	    if [ $DRY_RUN == "no" ]; then
                # Back up the ~/$dotfile
		mv ~/$dotfile ~/$dotfile.bak
	    fi
	fi
    else
	echo "no ~/$dotfile" 
	if [ $OVERRIDDEN == "no" ]; then
	    ADDED="$ADDED ~/$dotfile"
	fi
    fi
    if isPatchFile $file $PATCHFILES; then
	if [ $DRY_RUN == "no" ]; then
            # Install the patched ~/$dotfile
	    cp $file ~/$dotfile
	fi
    else
	if [ $DRY_RUN == "no" ]; then
            # Install a symlink ~/$dotfile	
	    linkFiles $file $dotfile
	fi
    fi
done

listFiles "Added" $ADDED
listFiles "Updated" $UPDATED
listFiles "NotChanged" $NOT_CHANGED
listFiles "Ignored" $IGNORED

# Revert the action of the patch on our dotfiles files now that we've
# installed the patched versions.
if [ -f "local.patch" ] && [ $DRY_RUN == "no" ]; then
    echo ""
    echo '$ patch -i local.patch -R'
    patch -i local.patch -R
fi
