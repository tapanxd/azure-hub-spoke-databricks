#!/usr/bin/env bash
# Guard a Terraform plan before it is applied.
#
# Usage: scripts/assert-plan.sh <plan.json> [import-only|no-destroy]
#   plan.json: output of `terraform show -json <planfile>`
#   import-only (default): every change must be a no-op (imports are no-ops) or a read.
#   no-destroy: nothing may be deleted, which includes replacements.
#
# Exit codes: 0 = plan passes, 1 = offending changes found, 2 = usage error.
set -euo pipefail

usage() {
  echo "usage: $0 <plan.json> [import-only|no-destroy]" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
PLAN=$1
MODE=${2:-import-only}

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 2; }
[[ -f "$PLAN" ]] || { echo "error: plan file not found: $PLAN" >&2; exit 2; }
jq -e 'type == "object"' "$PLAN" >/dev/null 2>&1 || { echo "error: not a JSON plan: $PLAN" >&2; exit 2; }

case "$MODE" in
  import-only)
    rule='Only imports and no-ops are allowed.'
    filter='select(.change.actions != ["no-op"] and .change.actions != ["read"])'
    ;;
  no-destroy)
    rule='Nothing may be deleted or replaced.'
    filter='select(.change.actions | index("delete"))'
    ;;
  *)
    usage
    ;;
esac

# Plans with no changes may omit resource_changes entirely.
offenders=$(jq -r ".resource_changes // [] | .[] | ${filter} | \"\(.change.actions | join(\",\")) \(.address)\"" "$PLAN")
imports=$(jq '[.resource_changes // [] | .[] | select(.change.importing != null)] | length' "$PLAN")
total=$(jq '.resource_changes // [] | length' "$PLAN")

if [[ -n "$offenders" ]]; then
  count=$(wc -l <<<"$offenders")
  result="FAIL (${MODE}): ${count} offending change(s). ${rule}"
else
  result="PASS (${MODE}): ${total} resource change(s) checked, none offending."
fi

echo "$result"
echo "Resources being imported: ${imports}"
if [[ -n "$offenders" ]]; then
  echo "Offending changes:"
  sed 's/^/  /' <<<"$offenders"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### Plan assertion: \`${MODE}\`"
    echo
    echo "**${result}**"
    echo
    echo "Resources being imported: ${imports}"
    if [[ -n "$offenders" ]]; then
      echo
      echo '```'
      echo "$offenders"
      echo '```'
    fi
  } >>"$GITHUB_STEP_SUMMARY"
fi

[[ -z "$offenders" ]]
