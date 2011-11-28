#!/bin/bash

if [ -z "${DOTFILES_DIR}" ]; then
    echo 'DOTFILES_DIR is not set.  Bailing out.'
    exit 1
fi

cd "${DOTFILES_DIR}" || exit 1

# Update once a week from our remote repository.  Mark updates by
# touching this file.
UPDATE_FILE="updated.$(date +%U)"

if [ ! -e "${UPDATE_FILE}" ]; then
    echo "update dotfiles"
    rm -f updated.* 2>/dev/null
    touch "${UPDATE_FILE}"
    ./bin/fetch.sh || exit 1
    ./bin/patch.sh || exit 1
    ./bin/link.sh || exit 1
    echo "dotfiles updated"
fi
