#!/bin/bash
#
# Get the current dotfiles from the server using a variety of methods.
#
# In order of decreasing preference:
#   if we have git installed
#     git over ssh, if there is an ssh agent running
#     git over http
#   otherwise
#     wget a tarball

# The default ssh url is stored in .git/config, so we don't need it here
http="http://einstein.physics.drexel.edu/~wking/code/git/dotfiles.git"
tgz="http://einstein.physics.drexel.edu/~wking/code/tar/dotfiles.tgz"


# Check for Git (versioning system) so we know how to get our .dotfiles
if [ -d .git ];then
   GIT_INSTALLED="true"
else
   GIT_INSTALLED="false"
fi

# Check for a SSH agent
if [ -n "$SS_AUTH_SOCK" ] && [ -n "$SSH_AGENT_PID" ]; then
   SSH_AGENT="true"
else
   SSH_AGENT="false"
fi

if [ $GIT_INSTALLED == "true" ]; then
    if [ $SSH_AGENT == "true" ]; then
	git pull || exit 1
    else
	git pull $http master || exit 1
    fi
else
    # fallback on wgetting the tarball
    pushd ~
    wget --output-document dotfiles.tgz $tgz || exit 1
    tar -xzvf dotfiles.tgz || exit 1
    rm -rf dotfiles.tgz || exit 1
    popd
fi
