#!/bin/bash
#
# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# This script runs Vivado in tcl mode and sources an apropriate tcl file to run
# all the steps to generate bitstream. When finished, the bitsream is copied to
# the result directory. Additionally, all the warnings and errors logged during
# synthesis and implementation are also copied to results/warning_summary.log
# To work properly, a git repository in the project directory is required.
# Run from the project root directory.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

mkdir -p results

# Remove only ignored Vivado products and build a fresh design.
git clean -fXd fpga
(
    cd fpga
    vivado -mode tcl -source scripts/generate_bitstream.tcl
)

bitstream_file="$(find fpga/build -type f -name "*.bit" -print -quit)"
if [[ -z "${bitstream_file}" ]]; then
    echo "Blad: Vivado nie utworzylo pliku .bit." >&2
    exit 1
fi

cp "${bitstream_file}" results/top_vga_basys3.bit

# Copy warnings and errors to a single log file in results
"${SCRIPT_DIR}/warning_summary.sh"
