#!/bin/sh
# install-release.sh — download a release asset atomically and install to /usr/local/bin.
#
# Separates download from extraction so curl's --retry logic works end-to-end.
# The `curl URL | tar -xz` pipe pattern defeats retries: when curl retries
# mid-stream, the bytes already piped to tar are corrupted and tar dies with
# "Error is not recoverable" before curl's second attempt lands. Downloading
# the whole asset to a temp file first keeps curl's retry budget intact.
#
# Usage:
#   install-release NAME URL TYPE DEST [EXTRACT_PATH]
#
#   NAME          label used only in log lines and error messages
#   URL           direct download URL (not a redirect landing page)
#   TYPE          raw-bin | tgz-bin | zip-bin
#   DEST          filename to create under /usr/local/bin
#   EXTRACT_PATH  (tgz-bin, zip-bin) path inside the archive to extract.
#                 Defaults to DEST.
#
# Types:
#   raw-bin   URL is the binary itself. Saved to /usr/local/bin/DEST, mode 0755.
#   tgz-bin   URL is a .tar.gz. EXTRACT_PATH is extracted, renamed to DEST.
#   zip-bin   URL is a .zip.    EXTRACT_PATH is extracted, renamed to DEST.
#
# Exits non-zero with a message that names the tool whenever download or
# extraction fails. No `curl | tar`, no `curl | bash`, no silent partial writes.

set -eu

name="${1:?install-release: NAME required}"
url="${2:?install-release: URL required}"
type="${3:?install-release: TYPE required}"
dest="${4:?install-release: DEST required}"
extract_path="${5:-$dest}"

echo "==> install-release: ${name} (${type}) <- ${url}"

tmp="$(mktemp --tmpdir "install-release-${name}.XXXXXX")"
scratch=""
cleanup() {
  rm -f "${tmp}"
  [ -n "${scratch}" ] && rm -rf "${scratch}"
  return 0
}
trap cleanup EXIT INT TERM

if ! curl --connect-timeout 30 --retry 8 --retry-all-errors --retry-max-time 300 \
  -fsSL -o "${tmp}" "${url}"; then
  echo "install-release: ${name}: curl failed from ${url}" >&2
  exit 1
fi

if [ ! -s "${tmp}" ]; then
  echo "install-release: ${name}: downloaded file is empty (${url})" >&2
  exit 1
fi

target="/usr/local/bin/${dest}"

case "${type}" in
  raw-bin)
    install -m 0755 "${tmp}" "${target}"
    ;;
  tgz-bin)
    scratch="$(mktemp -d --tmpdir "install-release-${name}-xtr.XXXXXX")"
    if ! tar -xzf "${tmp}" -C "${scratch}" "${extract_path}"; then
      echo "install-release: ${name}: tar -xzf failed extracting '${extract_path}'" >&2
      exit 1
    fi
    if [ ! -f "${scratch}/${extract_path}" ]; then
      echo "install-release: ${name}: extracted path '${extract_path}' not found in archive" >&2
      exit 1
    fi
    install -m 0755 "${scratch}/${extract_path}" "${target}"
    ;;
  zip-bin)
    scratch="$(mktemp -d --tmpdir "install-release-${name}-xtr.XXXXXX")"
    if ! unzip -q "${tmp}" "${extract_path}" -d "${scratch}"; then
      echo "install-release: ${name}: unzip failed extracting '${extract_path}'" >&2
      exit 1
    fi
    if [ ! -f "${scratch}/${extract_path}" ]; then
      echo "install-release: ${name}: extracted path '${extract_path}' not found in archive" >&2
      exit 1
    fi
    install -m 0755 "${scratch}/${extract_path}" "${target}"
    ;;
  *)
    echo "install-release: ${name}: unknown TYPE '${type}' (expected raw-bin | tgz-bin | zip-bin)" >&2
    exit 1
    ;;
esac

echo "    -> ${target}"
