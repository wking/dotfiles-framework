#!/bin/bash
#
# Link each FILE in patched-src to ~/FILE
#
# By default, link.sh only replaces missing files and simlinks.  You
# can optionally overwrite any local files by passing the --force
# option.

if [ -z "${DOTFILES_DIR}" ]; then
    echo 'DOTFILES_DIR is not set.  Bailing out.'
    exit 1
fi

DOTFILES_SRC="${DOTFILES_DIR}/patched-src"
FORCE='no'   # If 'file', overwrite existing files.
             # If 'yes', overwrite existing files and dirs.
DRY_RUN='no' # If 'yes', disable any actions that change the filesystem

# parse options
while [ -n "${1}" ]; do
    case "${1}" in
        '--force')
        FORCE='yes'
        ;;
        '--force-file')
        FORCE='file'
        ;;
        '--dry-run')
        DRY_RUN='yes'
        ;;
    esac
    shift
done

# Create the symbolic link, overriding the target if it exists.
#
# link_file( $file )
#
# Parameters:
# file - The file we're processing '.foo'
function link_file()
{
    FILE="${1}"
    if [ -e ~/"${FILE}" ] || [ -h ~/"${FILE}" ]; then
        if [ "${DRY_RUN}" = 'yes' ]; then
            echo "move ~/${FILE} to ~/${FILE}.bak"
        else
            echo -n 'move '
            mv -v ~/"${FILE}" ~/"${FILE}.bak" || exit 1
        fi
    fi
    if [ "${DRY_RUN}" = 'yes' ]; then
        echo "link ~/${FILE} to ${DOTFILES_DIR}/${FILE}"
    else
        echo -n 'link '
        ln -sv "${DOTFILES_DIR}/patched-src/${FILE}" ~/"${FILE}" || exit 1
    fi
}

cd "${DOTFILES_DIR}/patched-src" || exit 1

while read FILE; do
    if [ "${FILE}" = '.' ]; then
        continue
    fi
    FILE="${FILE:2}"  # strip the leading './'
    if [ "${DOTFILES_SRC}/${FILE}" -ef ~/"${FILE}" ]; then
        continue  # already simlinked
    fi
    if [ -d "${DOTFILES_SRC}/${FILE}" ] && [ -d ~/"${FILE}" ] && \
        [ "${FORCE}" != 'yes' ]; then
        echo "use --force to override the existing directory: ~/${FILE}"
        continue  # allow unlinked directories
    fi
    if [ -e ~/"${FILE}" ] && [ "${FORCE}" = 'no' ]; then
        echo "use --force to override the existing target: ~/${FILE}"
        continue  # target already exists
    fi
    link_file "${FILE}"
done < <(find .)
