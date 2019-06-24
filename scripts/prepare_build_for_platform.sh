# !/bin/bash

set -eu

BISON_DIR="$(pwd)"

# we can't use mktemp here, we need case sensitive tmp directory on Darwin
TMP_DIR="${BISON_DIR}/tmp"
if [[ -e "${TMP_DIR}" ]]; then
    echo "${TMP_DIR} alreadu exists, remove it and try again"
    exit 1
fi

mkdir "${TMP_DIR}"
trap 'rm -rf "${TMP_DIR}"' EXIT

PLATFORM="$(uname | tr '[:upper:]' '[:lower:]')"
PLATFORM_HEADERS_DIR="${BISON_DIR}/${PLATFORM}-lib"
PLATFORM_SOURCES_LIST="${PLATFORM}_srcs"
ANDROID_BP_PATH="${BISON_DIR}/Android.bp"

ask_if_continue() {
    echo "This script will"
    echo "- regenerate ${PLATFORM_HEADERS_DIR} directory"
    echo "- append definition of ${PLATFORM_SOURCES_LIST}  to ${ANDROID_BP_PATH}"
    read -p "continue? [y/N] " should_continue
    case "${should_continue}" in
        y|Y ) ;;
        * ) echo "aborting"; exit 1;;
    esac
}

configure_and_build() {
    (
        set -x
        cd "${TMP_DIR}"
        eval "${BISON_DIR}/configure"
        make
    )
}

copy_headers() {
    (
        set -x
        rm -rf "${PLATFORM_HEADERS_DIR}"
        mkdir "${PLATFORM_HEADERS_DIR}"
        cd "${TMP_DIR}/lib"
        find . -type f -name "*.h" \
             -exec rsync -R "{}" "${PLATFORM_HEADERS_DIR}" ";"
    )    
}

append_sources() {
    cd "${TMP_DIR}"
    echo "${PLATFORM_SOURCES_LIST} = [" >> "${ANDROID_BP_PATH}"
    for o_file in $(find lib -type f -name "*.o"); do
        if [[ "${o_file}" != "lib/main.o" ]]; then
            echo "    \"${o_file%.o}.c\"," >> "${ANDROID_BP_PATH}"
        fi
    done
    for o_file in $(find src -type f -name "*.o"); do
        o_file="${o_file#src/bison-}"
        echo "    \"src/${o_file%.o}.c\"," >> "${ANDROID_BP_PATH}"
    done
    echo "]" >> "${ANDROID_BP_PATH}"
}

ask_if_continue
configure_and_build
copy_headers
append_sources
