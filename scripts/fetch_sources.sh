# !/bin/bash

set -eu

VERSION="3.4"
BISON_SOURCES_URL="http://ftp.gnu.org/gnu/bison/bison-${VERSION}.tar.xz"

BISON_DIR="$(pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

ask_if_continue() {
    echo "This script will copy bison-${VERSION} sources to ${BISON_DIR}."
    read -p "continue? [y/N] " should_continue
    case "${should_continue}" in
        y|Y ) ;;
        * ) echo "aborting"; exit 1;;
    esac
}

get_sources() {
    (
        set -x
        cd "${TMP_DIR}"
        wget "${BISON_SOURCES_URL}" -q
        tar xf "bison-${VERSION}.tar.xz"
        cp -r "bison-${VERSION}/." "${BISON_DIR}"
    )
}

ask_if_continue
get_sources
