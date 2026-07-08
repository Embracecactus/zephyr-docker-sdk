#!/usr/bin/env bash
set -e

export PATH="${PYTHON_VENV_PATH:-/opt/python/venv}/bin:${PATH}"

printf '[zephyr-sdk] ZEPHYR_BASE=%s\n' "${ZEPHYR_BASE:-}"
printf '[zephyr-sdk] ZEPHYR_SDK_INSTALL_DIR=%s\n' "${ZEPHYR_SDK_INSTALL_DIR:-}"
printf '[zephyr-sdk] ZEPHYR_TOOLCHAIN_VARIANT=%s\n' "${ZEPHYR_TOOLCHAIN_VARIANT:-}"

REQ_MARKER="${HOME}/.cache/zephyr-sdk-requirements.synced"
REQ_FILE="${ZEPHYR_BASE:-}/scripts/requirements.txt"

if [ "${SYNC_ZEPHYR_REQUIREMENTS:-0}" = "1" ]; then
    if [ -n "${ZEPHYR_BASE:-}" ] && [ -f "${REQ_FILE}" ] && [ ! -f "${REQ_MARKER}" ]; then
        mkdir -p "$(dirname "${REQ_MARKER}")"
        printf '[zephyr-sdk] installing Python requirements from %s\n' "${REQ_FILE}"
        python3 -m pip install -r "${REQ_FILE}"
        touch "${REQ_MARKER}"
    else
        printf '[zephyr-sdk] Python requirements sync skipped; set ZEPHYR_BASE to a Zephyr tree with scripts/requirements.txt\n'
    fi
fi

exec "$@"
