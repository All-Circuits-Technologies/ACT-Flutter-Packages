#!/bin/bash

# SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

## This script wraps `dart pub global run mono_repo generate` to also patch
## the generated workflow files (flutter-version fix for semver values) and
## optionally update the Flutter SDK version across all mono_pkg.yaml files.
##
## The active version is persisted in tool/.flutter_version so that
## subsequent calls without --flutter-version (e.g. after adding a new package)
## can re-run generate + patch without re-specifying the version.
##
## Usage:
##  $0 [options]
##
## Options:
##  --help                     Show this help
##  --dry-run                  Print what would be done without changing any file
##  --flutter-version <value>  Set and persist a new Flutter SDK version before
##                             generating (e.g. "stable", "beta", "3.22.0").
##                             If omitted, the version from tool/.flutter_version
##                             is used and mono_pkg.yaml files are not changed.

set -e  # Die if a line ends in error
set -u  # Accessing an unknown variable is an error

# shellcheck disable=SC3040
set -o pipefail

VERSION=""
DRY_RUN=false
GENERATE_ONLY=false  # true when version is read from the stored file

FLUTTER_VERSION_FILE="tool/.flutter_version"

# Small helpers --------------------------------------------------------

die() {
    printf "%s\n" "$*" >&2
    exit 1
}

print_help() {
    grep "^##" "$0" | sed 's/^## \?//' | sed "s,\$0,$0,"
}

# Replaces the sdk block in a single mono_pkg.yaml file.
# Only the first encountered sdk block is rewritten; extra version entries
# (multiple `- x` lines under sdk:) are collapsed into the single new version.
update_sdk_in_file() {
    local file="$1"

    if "${DRY_RUN}"; then
        echo "[dry-run] Would update: ${file}"
        return
    fi

    local tmp_file
    tmp_file="$(mktemp)"

    awk -v version="${VERSION}" '
        /^sdk:/ {
            in_sdk = 1
            replaced = 0
            print
            next
        }
        in_sdk && /^  - / {
            if (!replaced) {
                print "  - \"" version "\""
                replaced = 1
            }
            # Additional version lines are dropped (collapsed to one)
            next
        }
        in_sdk {
            in_sdk = 0
        }
        { print }
    ' "${file}" > "${tmp_file}"

    mv "${tmp_file}" "${file}"
    echo "Updated: ${file}"
}

# Persists the current VERSION to FLUTTER_VERSION_FILE.
save_version() {
    if "${DRY_RUN}"; then
        echo "[dry-run] Would save version '${VERSION}' to ${FLUTTER_VERSION_FILE}"
        return
    fi
    printf '%s' "${VERSION}" > "${FLUTTER_VERSION_FILE}"
    echo "Saved version '${VERSION}' to ${FLUTTER_VERSION_FILE}"
}

# Iterates over every mono_pkg.yaml tracked by git and updates the sdk block.
update_all_packages() {
    local count=0

    while IFS= read -r pkg_file; do
        update_sdk_in_file "${pkg_file}"
        count=$((count + 1))
    done < <(git ls-files --recurse-submodules "*/mono_pkg.yaml")

    echo ""
    echo "${count} file(s) processed."
}

# Returns 0 if the version looks like a semver number (e.g. "3.41", "3.22.0"),
# returns 1 for channel names ("stable", "beta", "dev").
is_semver() {
    [[ "$1" =~ ^[0-9]+\.[0-9] ]]
}

# After mono_repo generate, subosito/flutter-action receives the sdk value as
# "channel:", which only accepts channel names. For numeric versions we must
# replace it with "flutter-version:" in every generated workflow file.
fix_flutter_action_in_workflows() {
    if ! is_semver "${VERSION}"; then
        return
    fi

    # Escape dots so they are treated as literals in the sed extended regex pattern.
    local escaped_version
    escaped_version=$(printf '%s' "${VERSION}" | sed 's/\./\\./g')

    local count=0
    while IFS= read -r workflow_file; do
        # mono_repo may quote the value ("3.41.9") or leave it unquoted.
        # Use extended regex (-E) with optional quotes: channel: "?<version>"?
        if grep -qE "channel: \"?${escaped_version}\"?" "${workflow_file}" 2>/dev/null; then
            sed -i -E "s/channel: \"?${escaped_version}\"?/flutter-version: \"${VERSION}\"/g" "${workflow_file}"
            echo "Fixed flutter-action in: ${workflow_file}"
            count=$((count + 1))
        fi
    done < <(find .github/workflows -name '*.yml' -o -name '*.yaml' 2>/dev/null)

    if [ "${count}" -gt 0 ]; then
        echo "${count} workflow file(s) patched."
    fi
}

# Runs mono_repo generate from the repository root.
run_mono_repo_generate() {
    if "${DRY_RUN}"; then
        echo "[dry-run] Would run: dart pub global run mono_repo generate"
        if is_semver "${VERSION}"; then
            echo "[dry-run] Would patch flutter-action channel → flutter-version in .github/workflows/"
        fi
        return
    fi

    echo ""
    echo "Running mono_repo generate..."
    dart pub global run mono_repo generate

    echo ""
    echo "Patching flutter-action in generated workflows..."
    fix_flutter_action_in_workflows
}

# Main -----------------------------------------------------------------

main() {
    while test $# -gt 0; do
        local OPT="$1"
        case "${OPT}" in
        --help)
            print_help
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --flutter-version)
            if [ -z "${2:-}" ]; then
                die "Option --flutter-version requires a value."
            fi
            if [ -n "${VERSION}" ]; then
                die "--flutter-version specified more than once."
            fi
            VERSION="$2"
            shift 2
            ;;
        -*)
            die "Unknown option: ${OPT}"
            ;;
        *)
            die "Unexpected argument: ${OPT}. Did you mean --flutter-version ${OPT}?"
            ;;
        esac
    done

    # Ensure we run from the repository root (where mono_repo.yaml lives)
    local script_dir
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    local repo_root
    repo_root="$(cd "${script_dir}/.." && pwd)"
    cd "${repo_root}"

    # If no version was given on the command line, read the stored one.
    if [ -z "${VERSION}" ]; then
        if [ ! -f "${FLUTTER_VERSION_FILE}" ]; then
            die "Error: no version specified and ${FLUTTER_VERSION_FILE} not found.\nRun '$0 --flutter-version <version>' at least once to set and persist the version."
        fi
        VERSION=$(cat "${FLUTTER_VERSION_FILE}")
        GENERATE_ONLY=true
        echo "No version argument given — using stored version '${VERSION}' (generate + patch only)."
    fi

    if "${GENERATE_ONLY}"; then
        run_mono_repo_generate
    else
        echo "Setting Flutter SDK version to '${VERSION}' in all mono_pkg.yaml files..."
        echo ""
        update_all_packages
        save_version
        run_mono_repo_generate
    fi
}

main "$@"
