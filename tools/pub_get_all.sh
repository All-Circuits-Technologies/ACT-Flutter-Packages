#!/bin/bash

# SPDX-FileCopyrightText: 2023 Benoît Rolandeau <benoit.rolandeau@allcircuits.com>
# SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

## This script is useful to get all the flutter library dependencies of the
## project. It searches for all the pubspec.yaml under the given path and call
## get dependencies method.
##
## Usage:
##  $0 [options] [command]
##
## Options:
##  --help      Show this help
##
## command:
##  Optional command for "flutter pub" calls, defaulting to "get"

set -e  # Die if a line ends in error
set -u  # Accessing an unknown variable is an error

# shellcheck disable=SC3040
set -o pipefail

# This represents the command to call for the "flutter pub" command
COMMAND="get"

# Small helpers --------------------------------------------------------

die() {
    printf "%s" "$*" >&2
    exit 1
}

print_help() {
    grep "^##" "$0" | sed 's/^## \?//' | sed "s,\0,$0,"
}

flutter-pub-X-all() {
    for i in $(git ls-files --recurse-submodules "*/pubspec.yaml")
    do
            echo "Call ${i}"
            (cd "${i%pubspec.yaml}" && flutter pub "${COMMAND}")
    done
}

# Main -----------------------------------------------------------------

main() {
    while test $# -gt 0
    do
        # Parse options
        local OPT="$1"
        case "${OPT}" in
        --help)
            print_help
            exit 0
            ;;
        -*)
            die "Unknown option $1"
            ;;
        *)
            COMMAND="${OPT}"
            shift
            ;;
        esac
    done

    flutter-pub-X-all
}

main "$@"
