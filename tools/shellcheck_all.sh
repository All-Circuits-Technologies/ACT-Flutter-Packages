#!/bin/sh

# SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

## This script calls `shellcheck` command on all shell scripts of the repo.
## Even if issues are found in a shell script, it continues checking next ones.
##
## Script final success/failure state is:
## - success if no issues are found
## - error if at least one issue was found in at least one shell script/
##
## It needs `shellcheck` program to be found in PATH.
## Its first use is to be callsed from .gitlab-ci.yml (gitlab pipeline)
## but one can call it locally.
##
## Note that this script attempts to list shell scripts using git first
## and fallback to a find search if git is not found (which likely occurs
## when run from docker images). In both cases, only shell files within CWD
## are searched hence calling this script from repo root is advised.
##
## See shellcheck links:
## - https://www.shellcheck.net
## - https://github.com/koalaman/shellcheck
## - https://hub.docker.com/r/koalaman/shellcheck/
## - https://hub.docker.com/r/koalaman/shellcheck-alpine
##
## USAGE
## =====
##
##     $0 [options]
##
## With:
##
## Options:
##  --verbose         Print parsed files (also print skipped file when doubled)
##  --exclude xx,yy   Ignore error xx and yy (ex: --ignore SC1017 ignores windows CLRF OEL)
##  --help            Show this help
##
## Environment variables
## =====================
##
## - GIT can be used to override git path
## - SHELLCHECK can be used to override shellcheck path
## - SHELLCHECK_OPTS can be used to provide additional arguments to shellcheck
## - OPT_VERBOSE=1 can be used as an alias for --verbose
## - OPT_VERBOSE=2 can be used as an alias for --verbose --verbose
##
## Configuration Files
## ===================
##
## .shellcheck/ignore.txt can list shell scripts to ignore (or substrings of)
## .shellcheck/args.txt can provide extra arguments to _this_ script
## .shellcheckrc can setup shellcheck inner call
## .shellcheckrc can be in any folder, it applies to subfolders as well

set -e
set -u
# shellcheck disable=SC3040
set -o pipefail


# Pattern used by both git ls-files and find -iname
readonly SHELL_FILENAME_PATTERN="*.sh"

# Variable holding a simple new line character, the POSIX way
NL="$(printf '\nx')"; NL="${NL%x}"
readonly NL

# Optional file listing one grep rule per line, mathing files are ignored
readonly CFG_FILE_IGNORE=".shellcheck/ignore.txt"

# Optional file containing extra arguments for this script
readonly CFG_FILE_ARGS=".shellcheck/args.txt"

# Path to git program
readonly GIT="${GIT:-git}"

# Path to shellcheck program
readonly SHELLCHECK="${SHELLCHECK:-shellcheck}"

# Extra shellcheck options
SHELLCHECK_OPTS="${SHELLCHECK_OPTS:-}"

# Should script be verbose
OPT_VERBOSE="${OPT_VERBOSE:-0}"


# --------------------------------------------------------

die() {
    printf "%s" "$*" >&2
    exit 1
}

print_help() {
    grep "^##" "$0" | sed 's/^## \?//' | sed "s,\$0,$0,"
}

# List shell files one per line
list_shell_files() {
    IFS="${NL}"
    "${GIT}" ls-files "${SHELL_FILENAME_PATTERN}" || find . -iname "${SHELL_FILENAME_PATTERN}"
}

is_file_ignored() {
    printf "%s" "$1" | grep -qf "${CFG_FILE_IGNORE}"
}

parse_args() {
    while test $# -gt 0
    do
        # Parse options
        OPT="$1"
        OPT_VAL="${2:-}"
        case "${OPT}" in
        --help)
            print_help
            exit 0
            ;;
        --exclude)
            SHELLCHECK_OPTS="${SHELLCHECK_OPTS:-} --exclude=${OPT_VAL}"
            shift 2
            ;;
        --verbose)
            OPT_VERBOSE="$(( OPT_VERBOSE + 1 ))"
            shift
            ;;
        -*)
            die "Unknown option $1, see --help"
            ;;
        *)
            die "This script does not accept individual file or folder argument, see --help"
            ;;
        esac
    done
}

main() {
    # Parse arguments (configuration file then explicit arguments)
    if test -f "${CFG_FILE_ARGS}"
    then
        # shellcheck disable=SC2046
        parse_args $(cat "${CFG_FILE_ARGS}")
    fi
    parse_args "$@"

    # Sanitize args
    # Actually acts as a workaround to ${SHELLCHECK_OPTS} being like enquoted
    # when later used, depite not being so. We then need do remove heading space.
    SHELLCHECK_OPTS="${SHELLCHECK_OPTS%% }"
    SHELLCHECK_OPTS="${SHELLCHECK_OPTS## }"

    # Do the job
    SUCCESS_COUNT="$((0))"
    FAILURE_COUNT="$((0))"
    IFS="${NL}"
    for file in $(list_shell_files)
    do
        if is_file_ignored "${file}"
        then
            if test "${OPT_VERBOSE}" -ge "2"
            then
                echo "Skipping ${file} ..."
            fi
            continue
        fi

        if test "${OPT_VERBOSE}" -ge "1"
        then
            echo "Checking ${file} ..."
        fi

        # shellcheck disable=SC2086
        if "${SHELLCHECK}" ${SHELLCHECK_OPTS:-} "${file}"
        then
            SUCCESS_COUNT="$(( SUCCESS_COUNT + 1 ))"
        else
            echo "Shell script '${file}' does not pass checks"
            FAILURE_COUNT="$(( FAILURE_COUNT + 1 ))"
            # Continue scaning other files
        fi
    done

    if test "${FAILURE_COUNT}" -gt 0
    then
        die "${FAILURE_COUNT}/$(( SUCCESS_COUNT + FAILURE_COUNT )) shell files do not pass checks"
    elif test "${SUCCESS_COUNT}" -eq 0
    then
        die "No shell script found, nothing checked"
    else
        echo "All ${SUCCESS_COUNT} analysed shell script passes the check :)"
    fi
}

main "$@"
