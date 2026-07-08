#!/usr/bin/env bash
set -e

export PATH="${PYTHON_VENV_PATH:-/opt/python/venv}/bin:${PATH}"

printf '[zephyr-sdk] ZEPHYR_BASE=%s\n' "${ZEPHYR_BASE:-}"
printf '[zephyr-sdk] ZEPHYR_SDK_INSTALL_DIR=%s\n' "${ZEPHYR_SDK_INSTALL_DIR:-}"
printf '[zephyr-sdk] ZEPHYR_TOOLCHAIN_VARIANT=%s\n' "${ZEPHYR_TOOLCHAIN_VARIANT:-}"

REQ_MARKER="${HOME}/.cache/zephyr-sdk-requirements.synced"
REQ_FILE="${ZEPHYR_BASE:-}/scripts/requirements.txt"

if [ "${SKIP_ZEPHYR_PIP_SYNC:-0}" != "1" ] && [ -f "${REQ_FILE}" ] && [ ! -f "${REQ_MARKER}" ]; then
    mkdir -p "$(dirname "${REQ_MARKER}")"
    printf '[zephyr-sdk] installing Python requirements from %s\n' "${REQ_FILE}"
    python3 -m pip install -r "${REQ_FILE}"
    touch "${REQ_MARKER}"
fi

exec "$@"
