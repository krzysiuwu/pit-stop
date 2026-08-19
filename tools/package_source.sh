#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
PROJECT_PARENT="$(dirname -- "${PROJECT_ROOT}")"
PROJECT_NAME="$(basename -- "${PROJECT_ROOT}")"
OUTPUT="${1:-${PROJECT_PARENT}/pit-stop-optimized.zip}"

if [[ "${OUTPUT}" != /* ]]; then
    OUTPUT="${PROJECT_ROOT}/${OUTPUT}"
fi

cd "${PROJECT_PARENT}"
zip -r -FS "${OUTPUT}" "${PROJECT_NAME}" \
    -x "${PROJECT_NAME}/.git/*" \
       "${PROJECT_NAME}/obj_dir/*" \
       "${PROJECT_NAME}/fpga/build/*" \
       "${PROJECT_NAME}/sim/build/*" \
       "${PROJECT_NAME}/results/*" \
       "${PROJECT_NAME}/.Xil/*" \
       "${PROJECT_NAME}/tools/__pycache__/*" \
       "${PROJECT_NAME}/**/__pycache__/*" \
       "${PROJECT_NAME}/*.jou" \
       "${PROJECT_NAME}/*.log" \
       "${PROJECT_NAME}/*.wdb" \
       "${PROJECT_NAME}/*.exe" \
       "${PROJECT_NAME}/*.vcd" \
       "${PROJECT_NAME}/*.pyc"

echo "Gotowe: ${OUTPUT}"
