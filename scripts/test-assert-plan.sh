#!/usr/bin/env bash
# Exit code for every fixture/mode pair. Only needs jq.
# No -e: half of these are supposed to exit non-zero.
set -uo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ASSERT="$DIR/assert-plan.sh"
FIX="$DIR/fixtures"

# don't write fixture results into the real CI step summary
unset GITHUB_STEP_SUMMARY

pass=0
fail=0

expect() {
  local want=$1 desc=$2
  shift 2
  "$ASSERT" "$@" >/dev/null 2>&1
  local got=$?
  if [[ $got -eq $want ]]; then
    echo "ok    ${desc} (exit ${got})"
    pass=$((pass + 1))
  else
    echo "FAIL  ${desc}: expected exit ${want}, got ${got}"
    fail=$((fail + 1))
  fi
}

expect 0 "import-clean     import-only"  "$FIX/import-clean.json" import-only
expect 0 "import-clean     no-destroy"   "$FIX/import-clean.json" no-destroy
expect 0 "import-clean     default mode" "$FIX/import-clean.json"
expect 0 "no-changes       import-only"  "$FIX/no-changes.json" import-only
expect 0 "no-changes       no-destroy"   "$FIX/no-changes.json" no-destroy
expect 1 "adds-resource    import-only"  "$FIX/adds-resource.json" import-only
expect 0 "adds-resource    no-destroy"   "$FIX/adds-resource.json" no-destroy
expect 1 "replace          import-only"  "$FIX/replace.json" import-only
expect 1 "replace          no-destroy"   "$FIX/replace.json" no-destroy
expect 1 "update-imported  import-only"  "$FIX/update-imported.json" import-only
expect 0 "update-imported  no-destroy"   "$FIX/update-imported.json" no-destroy

expect 2 "usage: no arguments"
expect 2 "usage: unknown mode"           "$FIX/import-clean.json" yolo
expect 2 "usage: missing file"           "$FIX/does-not-exist.json"
expect 2 "usage: not JSON"               "$ASSERT"
expect 2 "usage: too many arguments"     "$FIX/import-clean.json" import-only extra

echo
echo "${pass} passed, ${fail} failed"
[[ $fail -eq 0 ]]
