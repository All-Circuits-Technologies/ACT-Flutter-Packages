#!/bin/bash

# SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

## This script runs the unit tests of all the flutter packages of the project.
## It searches for all the pubspec.yaml under the given path and calls
## "flutter test" in the packages which have a test folder. The packages
## without tests are skipped, because "flutter test" fails when the test
## folder doesn't exist.
##
## The script runs every package before reporting; it exits in error if at
## least one package failed, and lists the failing packages.
##
## Usage:
##  $0 [options]
##
## Options:
##  --help      Show this help
##  --use-fvm   Use "fvm flutter" calls instead of "flutter".

set -u  # Accessing an unknown variable is an error

# shellcheck disable=SC3040
set -o pipefail

FVM_IF_NEEDED=""

# The packages which failed their tests
FAILURES=()

# Small helpers --------------------------------------------------------

die() {
    printf "%s" "$*" >&2
    exit 1
}

print_help() {
    grep "^##" "$0" | sed 's/^## \?//' | sed "s,\$0,$0,"
}

# Prints the arguments the package gives to "flutter test", if it gives any.
#
# A package which only runs its tests on one platform says so next to the test
# task of its mono_pkg.yaml; the CI reads the arguments from there, and so does
# this script.
test_args_of() {
    local mono_pkg="$1mono_pkg.yaml"

    if [ ! -f "${mono_pkg}" ]
    then
        return
    fi

    sed -n 's/^ *- test:  *\(.*\)$/\1/p' "${mono_pkg}" | head -n 1
}

flutter-test-all() {
    for i in $(git ls-files --recurse-submodules "*/pubspec.yaml")
    do
        local pkg_dir="${i%pubspec.yaml}"

        if [ ! -d "${pkg_dir}test" ]
        then
            echo "Skip ${pkg_dir} (no test folder)"
            continue
        fi

        local test_args
        test_args="$(test_args_of "${pkg_dir}")"

        echo "Test ${pkg_dir}"
        # The arguments are meant to be split into several ones
        # shellcheck disable=SC2086
        if ! (cd "${pkg_dir}" && ${FVM_IF_NEEDED} flutter test ${test_args})
        then
            FAILURES+=("${pkg_dir}")
        fi
    done
}

print_report() {
    echo ""

    if [ ${#FAILURES[@]} -eq 0 ]
    then
        echo "All the tested packages succeeded."
        return 0
    fi

    echo "${#FAILURES[@]} package(s) failed:"
    for pkg_dir in "${FAILURES[@]}"
    do
        echo "  ${pkg_dir}"
    done

    return 1
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
        --use-fvm)
            FVM_IF_NEEDED="fvm"
            shift
            ;;
        *)
            die "Unknown option $1"
            ;;
        esac
    done

    flutter-test-all
    print_report
}

main "$@"
