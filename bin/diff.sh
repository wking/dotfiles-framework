#!/bin/bash
#
# Print diffs for each _FILE, ~/.FILE pair
#
# There are two modes: removed and standard. In standard mode, we show
# the transition .file -> ~/.file, which shows the changes changes we
# need to apply to dotfiles to create your current local installation.
# In remove mode, we list the .files that do not have local ~/.file
# analogs (i.e. dotfiles that need to be removed to create your
# current local installation).  The --removed option selects removed
# mode.

if [ -z "${DOTFILES_DIR}" ]; then
    echo "DOTFILES_DIR is not set.  Bailing out."
    exit 1
fi

MODE='standard'

# parse options
while [ -n "${1}" ]; do
    case "${1}" in
        '--removed')
            MODE='removed'
            ;;
        '--local-patch')
            MODE='local-patch'
            ;;
    esac
    shift
done

if [ "${MODE}" = 'local-patch' ]; then
    cd "${DOTFILES_DIR}"
    mkdir -p local-patch || exit 1
    echo 'save local patches to local-patch/000-local.patch'
    ./bin/diff.sh > local-patch/000-local.patch || exit 1
    echo 'save local removes to local-patch/000-local.remove'
    ./bin/diff.sh --removed > local-patch/000-local.remove || exit 1
    exit
fi

cd "${DOTFILES_DIR}/src" || exit 1

# Show the changes we'd apply on installation
#
# Parameters:
# file - The file we're processing '.foo'
function handle_file()
{
    FILE="${1}"
    if [ "${MODE}" = 'removed' ]; then
        if [ ! -e ~/"${FILE}" ]; then
            echo "${FILE}"
        fi
    else
        if [ -f ~/"${FILE}" ]; then
            diff -u "${FILE}" ~/"${FILE}"
        fi
    fi
}

# For each file in this directory.
FOUND=0
while read FILE; do
    if [ "${FILE}" = '.' ]; then
        continue
    fi
    FILE="${FILE:2}"  # strip the leading './'
    handle_file "${FILE}"
    let "FOUND = FOUND + 1"
done < <(find .)

# If we found no .XXX files, print a warning
if [ "${FOUND}" -lt 1 ]; then
    echo 'WARNING: no source dotfiles were found' >&2
fi
