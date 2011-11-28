#!/bin/bash
#
# Get the current dotfiles from the server using a variety of methods.
#
# If there is a .git directory in $DOTFILES_DIR, use `git pull`,
# otherwise use wget to grab a tarball.

if [ -z "${DOTFILES_DIR}" ]; then
    echo 'DOTFILES_DIR is not set.  Bailing out.'
    exit 1
fi

cd "${DOTFILES_DIR}" || exit 1

# Check for Git (versioning system) so we know how to get our .dotfiles
if [ -d .git ];then
    git pull || exit 1
else
    # fallback on wgetting the tarball
    if [ -z "${DOTFILES_TGZ}" ]; then
        echo 'DOTFILES_TGZ is not set.  Bailing out.'
        exit 1
    fi
    wget --output-document dotfiles.tgz "${DOTFILES_TGZ}" || exit 1
    tar -xzvf dotfiles.tgz || exit 1
    rm -rf dotfiles.tgz || exit 1
fi
