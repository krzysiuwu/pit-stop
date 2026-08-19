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
# Run from the project root directory.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

mkdir -p results

# When available, Git removes only ignored Vivado products. A clean source ZIP
# has no .git directory; create_project -force and reset_run still provide a
# reproducible build there.
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git clean -fXd fpga
fi
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
