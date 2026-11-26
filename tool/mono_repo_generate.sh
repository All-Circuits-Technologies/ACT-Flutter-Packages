#!/bin/bash

# SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

## This script wraps `dart pub global run mono_repo generate` to also patch
## the generated workflow files (flutter-version fix for semver values) and
## optionally update the SDK versions across the mono_pkg.yaml files.
##
## The Flutter packages and the pure Dart packages (under dart/) take a
## different SDK version: the Flutter version for the first ones, the Dart
## version for the second ones, because the CI sets up a Dart SDK only for
## the pure Dart packages. Change both together: a Flutter release embeds a
## Dart release (`flutter --version` shows it), for example Flutter 3.47.9
## embeds Dart 3.13.7.
##
## The active versions are persisted in tool/.flutter_version and
## tool/.dart_version so that subsequent calls without options (e.g. after
## adding a new package) can re-run generate + patch without re-specifying
## the versions.
##
## Usage:
##  $0 [options]
##
## Options:
##  --help                     Show this help
##  --dry-run                  Print what would be done without changing any file
##  --flutter-version <value>  Set and persist a new Flutter SDK version in the
##                             mono_pkg.yaml files outside dart/ before
##                             generating (e.g. "stable", "beta", "3.22.0").
##                             If omitted, the version from tool/.flutter_version
##                             is used and those files are not changed.
##  --dart-version <value>     Set and persist a new Dart SDK version in the
##                             mono_pkg.yaml files under dart/ before generating
##                             (e.g. "3.13.7"). If omitted, those files are not
##                             changed.

set -e  # Die if a line ends in error
set -u  # Accessing an unknown variable is an error

# shellcheck disable=SC3040
set -o pipefail

VERSION=""  # The Flutter SDK version
DART_VERSION=""
DRY_RUN=false

FLUTTER_VERSION_FILE="tool/.flutter_version"
DART_VERSION_FILE="tool/.dart_version"

# The folder of the pure Dart packages, whose mono_pkg.yaml files take the Dart SDK version
PURE_DART_DIR="dart"

# Small helpers --------------------------------------------------------

die() {
    printf "%s\n" "$*" >&2
    exit 1
}

print_help() {
    grep "^##" "$0" | sed 's/^## \?//' | sed "s,\$0,$0,"
}

# Replaces the sdk block of the mono_pkg.yaml file given as first argument with
# the version given as second argument.
# Only the first encountered sdk block is rewritten; extra version entries
# (multiple `- x` lines under sdk:) are collapsed into the single new version.
update_sdk_in_file() {
    local file="$1"
    local version="$2"

    if "${DRY_RUN}"; then
        echo "[dry-run] Would update: ${file}"
        return
    fi

    local tmp_file
    tmp_file="$(mktemp)"

    awk -v version="${version}" '
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

# Persists the version given as first argument to the file given as second argument.
save_version() {
    local version="$1"
    local version_file="$2"

    if "${DRY_RUN}"; then
        echo "[dry-run] Would save version '${version}' to ${version_file}"
        return
    fi
    printf '%s' "${version}" > "${version_file}"
    echo "Saved version '${version}' to ${version_file}"
}

# Updates the sdk block of every mono_pkg.yaml tracked by git with the version
# given as first argument: the ones under PURE_DART_DIR when the second argument
# is "dart", the other ones when it is "flutter".
update_packages() {
    local version="$1"
    local kind="$2"
    local count=0

    while IFS= read -r pkg_file; do
        local is_pure_dart=false
        if [[ "${pkg_file}" == "${PURE_DART_DIR}/"* ]]; then
            is_pure_dart=true
        fi

        if [ "${kind}" = "dart" ] && ! "${is_pure_dart}"; then
            continue
        fi
        if [ "${kind}" = "flutter" ] && "${is_pure_dart}"; then
            continue
        fi

        update_sdk_in_file "${pkg_file}" "${version}"
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

# Replaces the `mono_repo generate --validate` command in the self-validate job
# with our own validation sequence: run the full generate+patch script then
# check git diff. This keeps the same job structure and action versions that
# mono_repo generates while adapting the command to the patched workflow.
fix_self_validate_in_workflows() {
    local count=0
    while IFS= read -r workflow_file; do
        if grep -q 'run: dart pub global run mono_repo generate --validate' "${workflow_file}" 2>/dev/null; then
            local tmp_file
            tmp_file="$(mktemp)"
            awk '
                /run: dart pub global run mono_repo generate --validate/ {
                    print "        run: |"
                    print "          bash tool/mono_repo_generate.sh"
                    print "          if ! git diff --exit-code; then"
                    print "            echo \"Generated files are out of sync. Run tool/mono_repo_generate.sh and commit.\""
                    print "            exit 1"
                    print "          fi"
                    next
                }
                { print }
            ' "${workflow_file}" > "${tmp_file}" && mv "${tmp_file}" "${workflow_file}"
            echo "Fixed self-validate in: ${workflow_file}"
            count=$((count + 1))
        fi
    done < <(find .github/workflows -name '*.yml' -o -name '*.yaml' 2>/dev/null)

    if [ "${count}" -gt 0 ]; then
        echo "${count} workflow file(s) self-validate patched."
    fi
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

    echo ""
    echo "Patching self-validate step in generated workflows..."
    fix_self_validate_in_workflows
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
        --dart-version)
            if [ -z "${2:-}" ]; then
                die "Option --dart-version requires a value."
            fi
            if [ -n "${DART_VERSION}" ]; then
                die "--dart-version specified more than once."
            fi
            DART_VERSION="$2"
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

    # If no Flutter version was given on the command line, read the stored one: the workflow
    # patches need it.
    if [ -z "${VERSION}" ]; then
        if [ ! -f "${FLUTTER_VERSION_FILE}" ]; then
            die "Error: no version specified and ${FLUTTER_VERSION_FILE} not found.\nRun '$0 --flutter-version <version>' at least once to set and persist the version."
        fi
        VERSION=$(cat "${FLUTTER_VERSION_FILE}")
        echo "No Flutter version argument given — using stored version '${VERSION}'."
    else
        echo "Setting Flutter SDK version to '${VERSION}' in the mono_pkg.yaml files outside ${PURE_DART_DIR}/..."
        echo ""
        update_packages "${VERSION}" flutter
        save_version "${VERSION}" "${FLUTTER_VERSION_FILE}"

        if [ -z "${DART_VERSION}" ]; then
            echo ""
            echo "Warning: the Dart SDK version of the ${PURE_DART_DIR}/ packages has not changed. Give the Dart version this Flutter version embeds with --dart-version."
        fi
    fi

    if [ -n "${DART_VERSION}" ]; then
        echo ""
        echo "Setting Dart SDK version to '${DART_VERSION}' in the mono_pkg.yaml files under ${PURE_DART_DIR}/..."
        echo ""
        update_packages "${DART_VERSION}" dart
        save_version "${DART_VERSION}" "${DART_VERSION_FILE}"
    fi

    run_mono_repo_generate
}

main "$@"
