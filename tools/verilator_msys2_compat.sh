#!/bin/bash

# MSYS2 GCC 16 currently compiles Verilator's runtime against the new
# libstdc++ string ABI, while the packaged runtime libraries expose the old
# ABI.  Return the compatibility define only for the affected toolchain.
verilator_msys2_cxx_abi_flag() {
    local cxx_command="${CXX:-g++}"
    local gcc_major

    case "${MSYSTEM:-}" in
        UCRT64|MINGW64|MINGW32)
            ;;
        *)
            return 1
            ;;
    esac

    if ! command -v "${cxx_command}" >/dev/null 2>&1; then
        return 1
    fi

    gcc_major="$("${cxx_command}" -dumpfullversion -dumpversion 2>/dev/null | cut -d. -f1)"
    if [[ "${gcc_major}" =~ ^[0-9]+$ ]] && ((gcc_major >= 16)); then
        printf '%s' '-D_GLIBCXX_USE_CXX11_ABI=0'
        return 0
    fi

    return 1
}
