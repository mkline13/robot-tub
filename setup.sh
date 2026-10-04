#!/bin/sh
# Creates the scopes and registers the schemas in this repo with the running
# `tub` container. Safe to re-run: existing scopes are skipped, and existing
# schemas are checked against their file (schemas can't change once added).
set -eu
cd "$(dirname "$0")"

CONTAINER=${TUB_CONTAINER:-tub}
SCOPES="personal"
tub() { docker exec -i "$CONTAINER" tub "$@"; }

for scope in $SCOPES; do
  if tub scopes list | awk 'NR > 1 { print $1 }' | grep -qx "$scope"; then
    echo "scope $scope: exists"
  else
    tub scopes create "$scope"
  fi
done

for file in schemas/*.json; do
  id=$(basename "$file" .json)
  if registered=$(tub schemas show "$id" 2>/dev/null); then
    # Compare as parsed JSON so formatting differences don't count.
    if printf '%s\n--tub-split--\n%s' "$registered" "$(cat "$file")" | docker exec -i "$CONTAINER" bun -e '
      const [a, b] = (await Bun.stdin.text()).split("\n--tub-split--\n")
      process.exit(Bun.deepEquals(JSON.parse(a), JSON.parse(b)) ? 0 : 1)
    ' 2>/dev/null; then
      echo "schema $id: exists"
    else
      echo "schema $id: registered version differs from $file; add a new id (e.g. ${id%.v*}.v2) instead of editing it" >&2
      exit 1
    fi
  else
    docker exec -i "$CONTAINER" sh -c 'f=$(mktemp) && cat > "$f" && tub schemas add "$1" "$f"; s=$?; rm -f "$f"; exit $s' sh "$id" < "$file"
  fi
done
