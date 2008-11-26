#!/bin/bash
#
# You're about to give your sysadmin account to some newbie, and
# they'd just be confused by all this efficiency.  This script freezes
# your dotfiles in their current state and makes everthing look
# normal.  Note that this will delete your ~/.dotfiles directory, and
# strip the .dotfiles portion from your ~/.bashrc file.

# See if the bashrc file is involved with .dotfiles at all
if [ -e _bashrc ]; then
    BASHRC="yes"
else
    BASHRC="no"
fi

# For each file in this directory.
for file in _*; do
    # Create .dotfile version.
    dotfile=.${file/_/}
    
    # Replace symlinks with their target
    if [ -h ~/$dotfile ]; then
	echo "De-symlink ~/$dotfile"
	rm -f ~/$dotfile
	mv $file ~/$dotfile
    fi
done

if [ $BASHRC == "yes" ]; then
    # We may have a dotfiles section in ~/.bashrc.  Strip it out.
    BC="### ---- begin .dotfiles section ---- (keep this magic comment)"
    EC="### ---- end .dotfiles section ---- (keep this magic comment)"
    AWKSCRIPT="BEGIN{copy=1}{"
    AWKSCRIPT="$AWKSCRIPT if(\$0 == \"$BC\"){copy=0};"
    AWKSCRIPT="$AWKSCRIPT if(\$0 == \"$EC\"){copy=1};"
    AWKSCRIPT="$AWKSCRIPT if(copy==1 && \$0 != \"$EC\"){print \$0}"
    AWKSCRIPT="$AWKSCRIPT}"
    
    echo "Strip dotfiles section from ~/.bashrc"
    awk "$AWKSCRIPT" ~/.bashrc > bashrc_stripped
    
    # see if the stripped file is any different
    DIFF=`diff ~/.bashrc bashrc_stripped`
    if [ $? -ne 1 ]; then exit 1; fi   # diff failed, bail
    if [ -n "$DIFF" ]; then
	echo "Replace ~/.bashrc with stripped version"
	rm -f ~/.bashrc
	cp bashrc_stripped ~/.bashrc
    else
	echo "No dotfiles section in ~/.bashrc"
    fi
fi

DOTFILES_DIR=`pwd`
cd
echo "Remove the dotfiles dir $DOTFILES_DIR"
rm -rf $DOTFILES_DIR
