#!/bin/bash
#
# Patch a fresh checkout with local adjustments.

if [ -z "${DOTFILES_DIR}" ]; then
    echo 'DOTFILES_DIR is not set.  Bailing out.'
    exit 1
fi

cd "${DOTFILES_DIR}" || exit 1

# clone the checkout into DOTFILES_DIR/patched-src
echo "clone clean checkout into patched-src"
rsync -avz --delete src/ patched-src/ || exit 1

# apply all the patches in local-patch/
for PATCH in local-patch/*.patch; do
    if [ -f "${PATCH}" ]; then
        echo "apply ${PATCH}"
        pushd patched-src/ > /dev/null || exit 1
        patch < "../${PATCH}" || exit 1
        popd > /dev/null || exit 1
    fi
done

# remove any files marked for removal in local-patch
for REMOVE in local-patch/*.remove; do
    if [ -f "${REMOVE}" ]; then
        while read LINE; do
            if [ -z "${LINE}" ] || [ "${LINE:0:1}" = '#' ]; then
                continue  # ignore blank lines and comments
            fi
            if [ -e "patched-src/${LINE}" ]; then
                echo "remove ${LINE}"
                rm -rf "patched-src/${LINE}"
            fi
        done < "${REMOVE}"
    fi
done
