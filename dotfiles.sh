#!/bin/bash
#
# Dotfiles management script.  For details, run
#   $ dotfiles.sh --help
#
# Copyright (C) 2011-2015 W. Trevor King <wking@tremily.us>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

VERSION='0.4'
DOTFILES_DIR="${PWD}"
TARGET=~
CHECK_WGET_TYPE_AND_ENCODING='no'

#####
# External utilities

DIFF=${DOTFILES_DIFF:-$(command -v diff)}
GIT=${DOTFILES_GIT:-$(command -v git)}
LN=${DOTFILES_LN:-$(command -v ln)}
MV=${DOTFILES_MV:-$(command -v mv)}
PATCH=${DOTFILES_PATCH:-$(command -v patch)}
SED=${DOTFILES_SED:-$(command -v sed)}
RM=${DOTFILES_RM:-$(command -v rm)}
RSYNC=${DOTFILES_RSYNC:-$(command -v rsync)}
TAR=${DOTFILES_TAR:-$(command -v tar)}
TOUCH=${DOTFILES_TOUCH:-$(command -v touch)}
WGET=${DOTFILES_WGET:-$(command -v wget)}

#####
# Compatibility checks

BASH="${BASH_VERSION%.*}"
BASH_MAJOR="${BASH%.*}"
BASH_MINOR="${BASH#*.}"

if [ "${BASH_MAJOR}" -eq 3 ] && [ "${BASH_MINOR}" -eq 0 ]; then
	echo "ERROR: ${0} requires Bash version >= 3.1" >&2
	echo "you're running ${BASH}, which doesn't support += array assignment" >&2
	exit 1
fi

#####
# Utility functions

# usage: nonempty_option LOC NAME VALUE
function nonempty_option()
{
	LOC="${1}"
	NAME="${2}"
	VALUE="${3}"
	if [ -z "${VALUE}" ]; then
		echo "ERROR: empty value for ${NAME} in ${LOC}" >&2
		return 1
	fi
	echo "${VALUE}"
}

# usage: maxargs LOC MAX "${@}"
#
# Print and error and return 1 if there are more than MAX arguments.
function maxargs()
{
	LOC="${1}"
	MAX="${2}"
	shift 2
	if [ "${#}" -gt "${MAX}" ]; then
		echo "ERROR: too many arguments (${#} > ${MAX}) in ${LOC}" >&2
		return 1
	fi
}

# usage: get_selection CHOICE OPTION ...
#
# Check that CHOICE is one of the valid options listed in OPTION.  If
# it is, echo the choice and return 0, otherwise print an error to
# stderr and return 1.
function get_selection()
{
	CHOICE="${1}"
	shift
	for OPT in "${@}"; do
	if [ "${OPT}" = "${CHOICE}" ]; then
		echo "${OPT}"
		return 0
	fi
	done
	echo "ERROR: invalid selection (${CHOICE})" >&2
	echo "valid choices: ${@}" >&2
	return 1
}

function run_on_all_repos()
{
	COMMAND="${1}"
	shift
	if [ -z "${REPO}" ]; then  # run on all repositories
		for REPO in *; do
			if [ "${REPO}" = '*' ]; then
				break  # no known repositories
			elif [ -f "${REPO}" ]; then
				continue  # repositories are directories
			fi
			"${COMMAND}" "${@}" "${REPO}" || return 1
		done
		return
	fi
}

function list_files()
{
	DIR=$(nonempty_option 'list_files' 'DIR' "${1}") || return 1
	while read FILE; do
		if [ "${FILE}" = '.' ]; then
			continue
		fi
		FILE="${FILE:2}"  # strip the leading './'
		echo "${FILE}"
	done < <(cd "${DIR}" && find .)
}

# Global variable to allow passing associative arrays between functions

if [ "${BASH_MAJOR}" -ge 4 ]; then
	declare -A REPO_SOURCE_DATA
fi

function set_repo_source()
{
	if [ "${BASH_MAJOR}" -lt 4 ]; then
		echo "ERROR: ${0}'s set_repo_source requires Bash version >= 4.0" >&2
		echo "you're running ${BASH}, which doesn't support associative arrays" >&2
		return 1
	fi
	REPO=$(nonempty_option 'set_repo_source' 'REPO' "${1}") || return 1
	> "${REPO}/source_cache" || return 1
	for KEY in "${!REPO_SOURCE_DATA[@]}"; do
		echo "${KEY}=${REPO_SOURCE_DATA[${KEY}]}" >> "${REPO}/source_cache" || return 1
	done
}

# usage: get_repo_source REPO
function get_repo_source()
{
	if [ "${BASH_MAJOR}" -lt 4 ]; then
		echo "ERROR: ${0}'s get_repo_source() requires Bash version >= 4.0" >&2
		echo "you're running ${BASH}, which doesn't support associative arrays" >&2
		return 1
	fi
	REPO=$(nonempty_option 'get_repo_source' 'REPO' "${1}") || return 1
	REPO_SOURCE_DATA=()
	if [ -f "${REPO}/source_cache" ]; then
		while read LINE; do
			KEY="${LINE%%=*}"
			VALUE="${LINE#*=}"
			REPO_SOURCE_DATA["${KEY}"]="${VALUE}"
		done < "${REPO}/source_cache"
	else
		# autodetect verson control system
		REPO_SOURCE_DATA=()
		REPO_SOURCE_DATA['repo']="${REPO}"
		if [ -d "${REPO}/.git" ]; then
			REPO_SOURCE_DATA['transfer']='git'
			REPO_SOURCE_DATA['url']=$(
				git --git-dir "${REPO}/.git/" config remote.origin.url)
		else
			echo "ERROR: no source location found for ${REPO}" >&2
			return 1
		fi
		# no need to get further fields for these transfer mechanisms
	fi
}

function git_fetch()
{
	REPO=$(nonempty_option 'git_fetch' 'REPO' "${1}") || return 1
	REMOTES=$(cd "${REPO}" && "${GIT}" remote) || return 1
	if [ -n "${REMOTES}" ]; then
		(cd "${REPO}" && "${GIT}" pull) || return 1
	else
		echo "no remote repositories found for ${REPO}"
	fi
}

function wget_fetch()
{
	REPO=$(nonempty_option 'wget_fetch' 'REPO' "${1}") || return 1
	# get_repo_source() was just called on this repo in fetch()
	TRANSFER=$(nonempty_option 'wget_fetch' 'TRANSFER' "${REPO_SOURCE_DATA['transfer']}") || return 1
	URL=$(nonempty_option 'wget_fetch' 'URL' "${REPO_SOURCE_DATA['url']}") || return 1
	ETAG="${REPO_SOURCE_DATA['etag']}"
	BUNDLE="${REPO}.tgz"
	HEAD=$("${WGET}" --server-response --spider "${URL}" 2>&1) || return 1
	SERVER_ETAG=$(echo "${HEAD}" | "${SED}" -n 's/^ *etag: *"\(.*\)"/\1/ip') || return 1
	if [ "${CHECK_WGET_TYPE_AND_ENCODING}" = 'yes' ]; then
		TYPE=$(echo "${HEAD}" | "${SED}" -n 's/^ *content-type: *//ip') || return 1
		ENCODING=$(echo "${HEAD}" | "${SED}" -n 's/^ *content-encoding: *//ip') || return 1
		if [ "${TYPE}" != 'application/x-gzip' ] || [ "${ENCODING}" != 'x-gzip' ]; then
			echo "ERROR: invalid content type (${TYPE}) or encoding (${ENCODING})." >&2
			echo "while fetching ${URL}" >&2
			return 1
		fi
	fi
	if [ -z "${ETAG}" ] || [ "${SERVER_ETAG}" != "${ETAG}" ]; then
		# Previous ETag not known, or ETag changed.  Download new copy.
		"${WGET}" --output-document "${BUNDLE}" "${URL}" || return 1
		if [ -n "${SERVER_ETAG}" ]; then  # store new ETag
			REPO_SOURCE_DATA['etag']="${SERVER_ETAG}"
			set_repo_source "${REPO}" || return 1
		elif [ -n "${ETAG}" ]; then  # clear old ETag
			unset "${REPO_SOURCE_DATA['etag']}"
			set_repo_source "${REPO}" || return 1
		fi
		echo "extracting ${BUNDLE} to ${REPO}"
		"${TAR}" -xf "${BUNDLE}" -C "${REPO}" --strip-components 1 --overwrite || return 1
		"${RM}" -f "${BUNDLE}" || return 1
	else
		echo "already downloaded the ETag=${ETAG} version of ${URL}"
	fi
}


# usage: link_file REPO FILE
#
# Create the symbolic link to the version of FILE in the REPO
# repository, overriding the target if it exists.  If you want to
# override the options passed to ${LN}, set LINK_OPTS.
function link_file()
{
	REPO=$(nonempty_option 'link_file' 'REPO' "${1}") || return 1
	FILE=$(nonempty_option 'link_file' 'FILE' "${2}") || return 1
	LINK_OPTS="${LINK_OPTS:--sv}"  # default to `-sv`
	if [ "${BACKUP}" = 'yes' ]; then
		if [ -e "${TARGET}/${FILE}" ] || [ -h "${TARGET}/${FILE}" ]; then
			if [ "${DRY_RUN}" = 'yes' ]; then
				echo "move ${TARGET}/${FILE} to ${TARGET}/${FILE}.bak"
			else
				echo -n 'move '
				mv -v "${TARGET}/${FILE}" "${TARGET}/${FILE}.bak" || return 1
			fi
		fi
	else
		if [ "${DRY_RUN}" = 'yes' ]; then
			echo "rm ${TARGET}/${FILE}"
		else
			"${RM}" -fv "${TARGET}/${FILE}"
		fi
	fi
	if [ "${DRY_RUN}" = 'yes' ]; then
		echo "link ${TARGET}/${FILE} to ${DOTFILES_DIR}/${REPO}/patched-src/${FILE}"
	else
		SOURCE="${DOTFILES_DIR}/${REPO}/patched-src/${FILE}"
		echo -n 'link '
		"${LN}" ${LINK_OPTS} "${SOURCE}" "${TARGET}/${FILE}" || return 1
	fi
}

#####
# Top-level commands

# An array of available commands
COMMANDS=()

###
# clone command

COMMANDS+=('clone')

CLONE_TRANSFERS=('git' 'wget')

function clone_help()
{
	echo 'Create a new dotfiles repository.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 ${COMMAND} REPO TRANSFER URL

		Where 'REPO' is the name the dotfiles repository to create,
		'TRANSFER' is the transfer mechanism, and 'URL' is the URL for the
		remote repository.  Valid TRANSFERs are:

		  ${CLONE_TRANSFERS[@]}

		Examples:

		  $0 clone public wget http://example.com/public-dotfiles.tar.gz
		  $0 clone private git ssh://example.com/~/private-dotfiles.git
	EOF
}

function clone()
{
	REPO=$(nonempty_option 'clone' 'REPO' "${1}") || return 1
	TRANSFER=$(nonempty_option 'clone' 'TRANSFER' "${2}") || return 1
	URL=$(nonempty_option 'clone' 'URL' "${3}") || return 1
	maxargs 'clone' 3 "${@}" || return 1
	TRANSFER=$(get_selection "${TRANSFER}" "${CLONE_TRANSFERS[@]}") || return 1
	if [ -e "${REPO}" ]; then
		echo "ERROR: destination path (${REPO}) already exists." >&2
		return 1
	fi
	CACHE_SOURCE='yes'
	FETCH='yes'
	case "${TRANSFER}" in
		'git')
			CACHE_SOURCE='no'
			FETCH='no'
			"${GIT}" clone "${URL}" "${REPO}" || return 1
			;;
		'wget')
			mkdir -p "${REPO}"
			;;
		*)
			echo "PROGRAMMING ERROR: add ${TRANSFER} support to clone command" >&2
			return 1
	esac
	if [ "${CACHE_SOURCE}" = 'yes' ]; then
		REPO_SOURCE_DATA=(['transfer']="${TRANSFER}" ['url']="${URL}")
		set_repo_source "${REPO}" || return 1
	fi
	if [ "${FETCH}" = 'yes' ]; then
		fetch "${REPO}" || return 1
	fi
}

###
# list command

COMMANDS+=('list')

function list_help()
{
	echo 'List current dotfiles repositories.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 ${COMMAND} [REPO]

		List information for 'REPO' in a form simular to the 'clone'
		command's arguments.  If 'REPO' is not give, all repositories will
		be listed.  Examples:

		  $0 list public
		  public wget http://example.com/public-dotfiles.tar.gz
		  $0 list
		  public wget http://example.com/public-dotfiles.tar.gz
		  private git ssh://example.com/~/private-dotfiles.git
	EOF
}

function list()
{
	# multi-repo case handled in main() by run_on_all_repos()
	REPO=$(nonempty_option 'list' 'REPO' "${1}") || return 1
	maxargs 'list' 1 "${@}" || return 1
	if [ "${BASH_MAJOR}" -ge 4 ]; then
		get_repo_source "${REPO}" || return 1
		TRANSFER=$(nonempty_option 'list' 'TRANSFER' "${REPO_SOURCE_DATA['transfer']}") || return 1
		URL=$(nonempty_option 'list' 'URL' "${REPO_SOURCE_DATA['url']}") || return 1
	else
		echo "WARNING: Bash version < 4.0, cannot use assuming all repos use git transfer" >&2
		TRANSFER='git'
		URL=$(git --git-dir "${REPO}/.git/" config remote.origin.url)
	fi
	echo "${REPO} ${TRANSFER} ${URL}"
}

###
# fetch command

COMMANDS+=('fetch')

function fetch_help()
{
	echo 'Get the current dotfiles from the server.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 ${COMMAND} [REPO]

		Where 'REPO' is the name the dotfiles repository to fetch.  If it
		is not given, all repositories will be fetched.
	EOF
}

function fetch()
{
	# multi-repo case handled in main() by run_on_all_repos()
	REPO=$(nonempty_option 'fetch' 'REPO' "${1}") || return 1
	maxargs 'fetch' 1 "${@}" || return 1
	if [ "${BASH_MAJOR}" -ge 4 ]; then
		get_repo_source "${REPO}" || return 1
		TRANSFER=$(nonempty_option 'fetch' 'TRANSFER' "${REPO_SOURCE_DATA['transfer']}") || return 1
	else
		echo "WARNING: Bash version < 4.0, assuming all repos use git transfer" >&2
		TRANSFER='git'
	fi
	if [ "${TRANSFER}" = 'git' ]; then
		git_fetch "${REPO}" || return 1
	elif [ "${TRANSFER}" = 'wget' ]; then
		wget_fetch "${REPO}" || return 1
	else
		echo "PROGRAMMING ERROR: add ${TRANSFER} support to fetch command" >&2
		return 1
	fi
}

###
# diff command

COMMANDS+=('diff')

function diff_help()
{
	echo 'Show differences between targets and dotfiles repositories.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 ${COMMAND} [--removed|--local-patch] [REPO]

		Where 'REPO' is the name the dotfiles repository to query.  If it
		is not given, all repositories will be queried.

		By default, ${COMMAND} will list differences between files that
		exist in both the target location and the dotfiles repository (as
		a patch that could be applied to the dotfiles source).

		With the '--removed' option, ${COMMAND} will list files that
		should be removed from the dotfiles source in order to match the
		target.

		With the '--local-patch' option, ${COMMAND} will create files in
		list files that should be removed from the dotfiles source in
		order to match the target.
	EOF
}

function diff()
{
	MODE='standard'
	while [ "${1::2}" = '--' ]; do
		case "${1}" in
			'--removed')
				MODE='removed'
				;;
			'--local-patch')
				MODE='local-patch'
				;;
			*)
				echo "ERROR: invalid option to diff (${1})" >&2
				return 1
			esac
		shift
	done
	# multi-repo case handled in main() by run_on_all_repos()
	REPO=$(nonempty_option 'diff' 'REPO' "${1}") || return 1
	maxargs 'diff' 1 "${@}" || return 1

	if [ "${MODE}" = 'local-patch' ]; then
		mkdir -p "${REPO}/local-patch" || return 1

		exec 3<&1     # save stdout to file descriptor 3
		echo "save local patches to ${REPO}/local-patch/000-local.patch"
		exec 1>"${REPO}/local-patch/000-local.patch"  # redirect stdout
		diff "${REPO}"
		exec 1<&3     # restore old stdout
		exec 3<&-     # close temporary fd 3

		exec 3<&1     # save stdout to file descriptor 3
		echo "save local removed to ${REPO}/local-patch/000-local.remove"
		exec 1>"${REPO}/local-patch/000-local.remove"  # redirect stdout
		diff --removed "${REPO}"
		exec 1<&3     # restore old stdout
		exec 3<&-     # close temporary fd 3
		return
	fi

	while read FILE; do
		if [ "${MODE}" = 'removed' ]; then
			if [ ! -e "${TARGET}/${FILE}" ]; then
				echo "${FILE}"
			fi
		elif [ -f "${TARGET}/${FILE}" ]; then
			(cd "${REPO}/src" && "${DIFF}" -u "${FILE}" "${TARGET}/${FILE}")
		fi
	done <<-EOF
		$(list_files "${REPO}/src")
	EOF
}

###
# patch command

COMMANDS+=('patch')

function patch_help()
{
	echo 'Patch a fresh checkout with local adjustments.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 ${COMMAND} [REPO]

		Where 'REPO' is the name the dotfiles repository to patch.  If it
		is not given, all repositories will be patched.
	EOF
}

function patch()
{
	# multi-repo case handled in main() by run_on_all_repos()
	REPO=$(nonempty_option 'patch' 'REPO' "${1}") || return 1
	maxargs 'patch' 1 "${@}" || return 1

	echo "copy clean checkout into ${REPO}/patched-src"
	"${RSYNC}" -avz --delete "${REPO}/src/" "${REPO}/patched-src/" || return 1

	# apply all the patches in local-patch/
	for FILE in "${REPO}/local-patch"/*.patch; do
		if [ -f "${FILE}" ]; then
			echo "apply ${FILE}"
			pushd "${REPO}/patched-src/" > /dev/null || return 1
			"${PATCH}" -p1 < "../../${FILE}" || return 1
			popd > /dev/null || return 1
		fi
	done

	# remove any files marked for removal in local-patch
	for REMOVE in "${REPO}/local-patch"/*.remove; do
		if [ -f "${REMOVE}" ]; then
			echo "apply ${FILE}"
			while read LINE; do
				if [ -z "${LINE}" ] || [ "${LINE:0:1}" = '#' ]; then
					continue  # ignore blank lines and comments
				fi
				if [ -e "${REPO}/patched-src/${LINE}" ]; then
					echo "remove ${LINE}"
					"${RM}" -rf "${REPO}/patched-src/${LINE}"
				fi
			done < "${REMOVE}"
		fi
	done
}

###
# link command

COMMANDS+=('link')

function link_help()
{
	echo 'Link a fresh checkout with local adjustments.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 ${COMMAND} [--force] [--force-dir] [--force-file] [--force-link]
		           [--dry-run] [--no-backup] [--relative] [REPO]

		Where 'REPO' is the name the dotfiles repository to link.  If it
		is not given, all repositories will be linked.

		By default, ${COMMAND} only replaces missing directories, files,
		simlinks.  You can optionally overwrite any local stuff by passing
		the --force option.  If you only want to overwrite a particular
		type, use the more granular --force-dir, etc.

		If you have coreutils 8.16 (2012-03-26) or greater, you can set
		the --relative option to create symlinks that use relative paths.
	EOF
}

function link()
{
	FORCE_DIR='no'    # If 'yes', overwrite existing directories.
	FORCE_FILE='no'   # If 'yes', overwrite existing files.
	FORCE_LINK='no'   # If 'yes', overwrite existing symlinks.
	DRY_RUN='no' # If 'yes', disable any actions that change the filesystem
	BACKUP_OPT='yes'
	LINK_OPTS='-sv'
	while [ "${1::2}" = '--' ]; do
		case "${1}" in
			'--force')
				FORCE_DIR='yes'
				FORCE_FILE='yes'
				FORCE_LINK='yes'
				;;
			'--force-dir')
				FORCE_DIR='yes'
				;;
			'--force-file')
				FORCE_FILE='yes'
				;;
			'--force-link')
				FORCE_LINK='yes'
				;;
			'--dry-run')
				DRY_RUN='yes'
				;;
			'--no-backup')
				BACKUP_OPT='no'
				;;
			'--relative')
				LINK_OPTS="${LINK_OPTS} --relative"
				;;
			*)
				echo "ERROR: invalid option to link (${1})" >&2
				return 1
		esac
		shift
	done
	# multi-repo case handled in main() by run_on_all_repos()
	REPO=$(nonempty_option 'link' 'REPO' "${1}") || return 1
	maxargs 'link' 1 "${@}" || return 1
	DOTFILES_SRC="${DOTFILES_DIR}/${REPO}/patched-src"

	while read FILE; do
		BACKUP="${BACKUP_OPT}"
		if [ "${DOTFILES_SRC}/${FILE}" -ef "${TARGET}/${FILE}" ]; then
			if [ "${FORCE_LINK}" = 'no' ]; then
				# don't prompt about --force-link, because this will happen a lot
				continue  # already simlinked
			elif [ ! -h "${TARGET}/${FILE}" ]; then
				# target file/dir underneath an already symlinked dir
				continue
			else
				# don't backup links that already point to the right place
				BACKUP='no'
			fi
		else
			if [ -d "${DOTFILES_SRC}/${FILE}" ] && [ -d "${TARGET}/${FILE}" ] && \
				[ "${FORCE_DIR}" = 'no' ]; then
				echo "use --force-dir to override the existing directory: ${TARGET}/${FILE}"
				continue  # allow unlinked directories
			elif [ -f "${TARGET}/${FILE}" ] && [ "${FORCE_FILE}" = 'no' ]; then
				echo "use --force-file to override the existing target: ${TARGET}/${FILE}"
				continue  # target already exists
			fi
		fi
		link_file "${REPO}" "${FILE}" || return 1
	done <<-EOF
		$(list_files "${DOTFILES_SRC}")
	EOF
}

###
# disconnect command

COMMANDS+=('disconnect')

function disconnect_help()
{
	echo 'Freeze dotfiles at their current state.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 ${COMMAND} [REPO]

		Where 'REPO' is the name the dotfiles repository to disconnect.
		If it is not given, all repositories will be disconnected.

		You're about to give your sysadmin account to some newbie, and
		they'd just be confused by all this efficiency.  This script
		freezes your dotfiles in their current state and makes everthing
		look normal.  Note that this will delete your dotfiles repository
		and strip the dotfiles portion from your ~/.bashrc file.
	EOF
}

function disconnect()
{
	# multi-repo case handled in main() by run_on_all_repos()
	REPO=$(nonempty_option 'disconnect' 'REPO' "${1}") || return 1
	maxargs 'disconnect' 1 "${@}" || return 1
	DOTFILES_SRC="${DOTFILES_DIR}/${REPO}/patched-src"

	# See if we've constructed any patched source files that might be
	# possible link targets
	if [ ! -d "${DOTFILES_SRC}" ]; then
		echo 'no installed dotfiles to disconnect'
		return
	fi

	# See if the bashrc file is involved with dotfiles at all
	BASHRC='no'

	while read FILE; do
		if [ "${FILE}" = '.bashrc' ] && [ "${TARGET}" -ef "${HOME}" ]; then
			BASHRC='yes'
		fi
		if [ "${DOTFILES_SRC}/${FILE}" -ef "${TARGET}/${FILE}" ] && [ -h "${TARGET}/${FILE}" ]; then
			# break simlink
			echo "de-symlink ${TARGET}/${FILE}"
			"${RM}" -f "${TARGET}/${FILE}"
			"${MV}" "${DOTFILES_SRC}/${FILE}" "${TARGET}/${FILE}"
		fi
	done <<-EOF
		$(list_files "${REPO}/patched-src")
	EOF

	if [ "${BASHRC}" == 'yes' ]; then
		echo 'strip dotfiles section from ~/.bashrc'
		"${SED}" '/DOTFILES_DIR/d' ~/.bashrc > bashrc_stripped

		# see if the stripped file is any different
		DIFF_OUTPUT=$("${DIFF}" ~/.bashrc bashrc_stripped)
		DIFF_RC="${?}"
		if [ "${DIFF_RC}" -eq 0 ]; then
			echo "no dotfiles section found in ~/.bashrc"
			"${RM}" -f bashrc_stripped
		elif [ "${DIFF_RC}" -eq 1 ]; then
			echo "replace ~/.bashrc with stripped version"
			"${RM}" -f ~/.bashrc
			"${MV}" bashrc_stripped ~/.bashrc
		else
			return 1  # diff failed, bail
		fi
	fi

	if [ -d "${DOTFILES_DIR}/${REPO}" ]; then
		echo "remove the ${REPO} repository"
		"${RM}" -rf "${DOTFILES_DIR}/${REPO}"
	fi
}

###
# update command

COMMANDS+=('update')

function update_help()
{
	echo 'Utility command that runs fetch, patch, and link.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 ${COMMAND} [options] [REPO]

		Where 'REPO' is the name the dotfiles repository to update.
		If it is not given, all repositories will be updateed.

		Run 'fetch', 'patch', and 'link' sequentially on each repository
		to bring them in sync with the central repositories.  Keeps track
		of the last update time to avoid multiple fetches in the same
		week.

		${COMMAND} passes any options it receives through to the link
		command.
	EOF
}

function update()
{
	LINK_OPTS=''
	while [ "${1::2}" = '--' ]; do
		LINK_OPTS="${LINK_FN_OPTS} ${1}"
		shift
	done
	# multi-repo case handled in main() by run_on_all_repos()
	REPO=$(nonempty_option 'update' 'REPO' "${1}") || return 1
	maxargs 'disconnect' 1 "${@}" || return 1

	# Update once a week from our remote repository.  Mark updates by
	# touching this file.
	UPDATE_FILE="${REPO}/updated.$(date +%U)"

	if [ ! -e "${UPDATE_FILE}" ]; then
		echo "update ${REPO} dotfiles"
		"${RM}" -f "${REPO}"/updated.* || return 1
		"${TOUCH}" "${UPDATE_FILE}" || return 1
		fetch "${REPO}" || return 1
		patch "${REPO}" || return 1
		link ${LINK_OPTS} "${REPO}" || return 1
		echo "${REPO} dotfiles updated"
	fi
}

#####
# Main entry-point

function main_help()
{
	echo 'Dotfiles management script.'
	if [ "${1}" = '--one-line' ]; then return; fi

	cat <<-EOF

		usage: $0 [OPTIONS] COMMAND [ARGS]

		Options:
		--help	Print this help message and exit.
		--version	Print the $0 version and exit.
		--dotfiles-dir DIR	Directory containing the dotfiles reposotories.  Defaults to '.'.
		--target DIR	Directory to install dotfiles into.  Defaults to '~'.

		Commands:
	EOF
	for COMMAND in "${COMMANDS[@]}"; do
			echo -en "${COMMAND}\t"
			"${COMMAND}_help" --one-line
	done
	cat <<-EOF

		To get help on any command, pass the '--help' as the first option
		to the command.  For example:

		  ${0} ${COMMANDS[0]} --help
	EOF
}

function main()
{
	COMMAND=''
	while [ "${1::2}" = '--' ]; do
		case "${1}" in
			'--help')
				main_help || return 1
				return
				;;
			'--version')
				echo "${VERSION}"
				return
				;;
			'--dotfiles-dir')
				DOTFILES_DIR="${2}"
				shift
				;;
			'--target')
				TARGET="${2}"
				shift
				;;
			*)
				echo "ERROR: invalid option to ${0} (${1})" >&2
				return 1
		esac
		shift
	done
	COMMAND=$(get_selection "${1}" "${COMMANDS[@]}") || return 1
	shift

	cd "${DOTFILES_DIR}" || return 1

	if [ "${1}" = '--help' ]; then
		"${COMMAND}_help" || return 1
	elif [ "${COMMAND}" = 'clone' ]; then
		"${COMMAND}" "${@}" || return 1
	else
		OPTIONS=()
		while [ "${1::2}" = '--' ]; do
			OPTIONS+=("${1}")
			shift
		done
		if [ "${#}" -eq 0 ]; then
			run_on_all_repos "${COMMAND}" "${OPTIONS[@]}" || return 1
		else
			maxargs "${0}" 1 "${@}" || return 1
			"${COMMAND}" "${OPTIONS[@]}" "${1}" || return 1
		fi
	fi
}

main "${@}" || exit 1
