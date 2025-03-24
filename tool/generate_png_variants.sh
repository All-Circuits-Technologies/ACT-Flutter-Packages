#!/bin/bash

# SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
#
# SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

## This script takes one or several picture files (ideally PNG, can also be JPG)
## and generate sized PNGs for all of them. Input file must be at least as large
## as 4.0x for result to not be blur.
##
## It requires ImageMagick to be accessible from PATH.
##
## USAGE: $0 --width X big-images  [--width Y other-big-images]
##
## With:
##
## big-images   Relative or absolute path to one or more image files
##
## Options:
##  --width X   Enforce image reference width (1:1) to X pixels statring from
##              it. Required at least before first big image.
##  --help      Show this help

set -e
set -u

readonly GRAPH_ASSETS_DIR="./assets/graphics"

# Options --------------------------------------------------------------

PNG_REF_WIDTH=""

# Small helpers --------------------------------------------------------

die() {
	printf "%s" "$*" >&2
	exit 1
}

print_help() {
	grep "^##" "$0" | sed 's/^## \?//' | sed "s,\$0,$0,"
}

# Unit workers ---------------------------------------------------------

# Export a single PNG file ($1) as several PNG files (0.75..4x)
process_single_png() {
	declare -r png_file_path="$1"
	test -f "${png_file_path}" || die "${png_file_path}: file not found"

    declare -r png_filename="${png_file_path##*/}"
	echo -n "${png_filename} "

    declare -r png_filestem="${png_filename%.*}"

	if [[ -z "${PNG_REF_WIDTH}" ]]
	then
		die "Undefined reference width, can not resize image,see --help"
	fi

	magick "${png_file_path}" -resize "$(( PNG_REF_WIDTH * 1     ))x" "${GRAPH_ASSETS_DIR}/${png_filestem}.png"       ; echo -n "."
    magick "${png_file_path}" -resize "$(( PNG_REF_WIDTH * 3 / 4 ))x" "${GRAPH_ASSETS_DIR}/0.75x/${png_filestem}.png" ; echo -n "."
    magick "${png_file_path}" -resize "$(( PNG_REF_WIDTH * 3 / 2 ))x" "${GRAPH_ASSETS_DIR}/1.5x/${png_filestem}.png"  ; echo -n "."
    magick "${png_file_path}" -resize "$(( PNG_REF_WIDTH * 2     ))x" "${GRAPH_ASSETS_DIR}/2.0x/${png_filestem}.png"  ; echo -n "."
    magick "${png_file_path}" -resize "$(( PNG_REF_WIDTH * 3     ))x" "${GRAPH_ASSETS_DIR}/3.0x/${png_filestem}.png"  ; echo -n "."
    magick "${png_file_path}" -resize "$(( PNG_REF_WIDTH * 4     ))x" "${GRAPH_ASSETS_DIR}/4.0x/${png_filestem}.png"  ; echo -n "."

	echo ""
}


# Macro-workers --------------------------------------------------------


# Parse command line options and fire
main() {
	# At least one argument required
	if test $# -eq 0
	then
		print_help
		exit 1
	fi

	# Iterate over arguments
	while test $# -gt 0
	do
		# Parse options
		local OPT="$1"
		local OPTVAL="${2:-}"
		case "${OPT}" in
		--width)
			test -n "${OPTVAL}" -a "${OPTVAL}" -gt 0 || die "Invalid width option argument '${OPTVAL}'"
			PNG_REF_WIDTH="${OPTVAL}"
			shift 2;
			continue
			;;
		--help)
			print_help
			exit 0
			;;
		-*)
			die "Unknown option $1"
			;;
		esac

		if test -f "$1"
		then
			# relative or absolute full path
			process_single_png "$1"
		else
			# Failed to locate SVG file to process
			die "Failed to locate PNG file '$1'"
		fi

		shift
	done
}

main "$@"
