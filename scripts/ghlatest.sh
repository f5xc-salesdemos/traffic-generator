#!/bin/sh
# Resolve the latest GitHub release version for a given repository.
# Usage: ghlatest owner/repo
# Returns the version string (without leading 'v') on stdout.
set -eu
repo="$1"
attempt=0
max=8
delay=5
ver=""
while [ "$attempt" -lt "$max" ]; do
  ver=$(curl -fsSL -o /dev/null -w '%{url_effective}' \
    "https://github.com/${repo}/releases/latest" 2>/dev/null |
    sed 's|.*/||;s|^v||') &&
    [ -n "$ver" ] && [ "$ver" = "${ver##*/}" ] &&
    {
      echo "$ver"
      exit 0
    }
  attempt=$((attempt + 1))
  echo "ghlatest: ${repo} attempt ${attempt}/${max} failed (got '${ver}'), retrying in ${delay}s..." >&2
  sleep "$delay"
  delay=$((delay * 2))
done
echo "ghlatest: ${repo} failed after ${max} attempts" >&2
exit 1
