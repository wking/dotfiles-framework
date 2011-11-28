#!/bin/bash
#
# You're about to give your sysadmin account to some newbie, and
# they'd just be confused by all this efficiency.  This script freezes
# your dotfiles in their current state and makes everthing look
# normal.  Note that this will delete your dotfiles directory, and
# strip the dotfiles portion from your ~/.bashrc file.

if [ -z "${DOTFILES_DIR}" ]; then
    echo 'DOTFILES_DIR is not set.  Bailing out.'
    exit 1
fi

# See if we've constructed any patched source files that might be
# possible link targets
if [ ! -d "${DOTFILES_DIR}/patched-src" ]; then
    echo 'no installed dotfiles to disconnect'
    exit
fi

DOTFILES_SRC="${DOTFILES_DIR}/patched-src"
cd "${DOTFILES_SRC}" || exit 1

# See if the bashrc file is involved with dotfiles at all
if [ -e '.bashrc' ]; then
    BASHRC='yes'
else
    BASHRC='no'
fi

while read FILE; do
    if [ "${FILE}" = '.' ]; then
        continue
    fi
    FILE="${FILE:2}"  # strip the leading './'
    if [ "${DOTFILES_SRC}/${FILE}" -ef ~/"${FILE}" ] && \
        [ -h ~/"${FILE}" ]; then
        # break simlink
        echo "de-symlink ~/${FILE}"
        rm -f ~/"${FILE}"
        mv "${FILE}" ~/"${FILE}"
    fi
done < <(find .)

if [ "${BASHRC}" == 'yes' ]; then
    echo 'strip dotfiles section from ~/.bashrc'
    sed '/DOTFILES_DIR/d' ~/.bashrc > bashrc_stripped

    # see if the stripped file is any different
    DIFF=$(diff ~/.bashrc bashrc_stripped)
    DIFF_RC="$?"
    if [ ${DIFF_RC} -eq 0 ]; then
        echo "no dotfiles section found in ~/.bashrc"
        rm -f bashrc_stripped
    elif [ ${DIFF_RC} -eq 1 ]; then
        echo "replace ~/.bashrc with stripped version"
        rm -f ~/.bashrc
        mv bashrc_stripped ~/.bashrc
    else
        exit 1  # diff failed, bail
    fi
fi

#if [ -d "${DOTFILES_DIR}" ]; then
#    cd
#    echo "remove the dotfiles dir ${DOTFILES_DIR}"
#    rm -rf "${DOTFILES_DIR}"
#fi
