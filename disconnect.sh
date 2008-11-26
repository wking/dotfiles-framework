#!/bin/bash
#
# You're about to give your sysadmin account to some newbie, and
# they'd just be confused by all this efficiency.  This script freezes
# your dotfiles in their current state and makes everthing look
# normal.  Note that this will delete your ~/.dotfiles directory, and
# strip the .dotfiles portion from your ~/.bashrc file.

# For each file in this directory.
for file in _*; do
    # Create .dotfile version.
    dotfile=.${file/_/}
    
    # Replace symlinks with their target
    if [ -h ~/$dotfile ]; then
	echo -n ""
	#rm -f ~/$dotfile
	#mv $file ~/$dotfile
    fi
done

# See if the bashrc file is involved with .dotfiles at all
if [ ! -e _bashrc ]; then
    # No _bashrc file, so leave ~/.bashrc alone
    exit
fi

# We may have a dotfiles section in ~/.bashrc.  Strip it out.
BC="### ---- begin .dotfiles section ---- (keep this magic comment)"
EC="### ---- end .dotfiles section ---- (keep this magic comment)"
AWKSCRIPT="BEGIN{copy=1}{"
AWKSCRIPT="$AWKSCRIPT if(\$0 == \"$BC\"){copy=0};"
AWKSCRIPT="$AWKSCRIPT if(\$0 == \"$EC\"){copy=1};"
AWKSCRIPT="$AWKSCRIPT if(copy==1 && \$0 != \"$EC\"){print \$0}"
AWKSCRIPT="$AWKSCRIPT}"

awk "$AWKSCRIPT" ~/.bashrc > bashrc_stripped
# see if the stripped file is any different
DIFF=`diff ~/.bashrc bashrc_stripped` || exit 1
if [ -n "$DIFF" ]

rm -f ~/.bashrc
cp bashrc_stripped ~/.bashrc
