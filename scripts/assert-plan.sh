#!/usr/bin/env bash
# Fails if a plan does more than it should.
#
#   scripts/assert-plan.sh plan.json [import-only|no-destroy]
#
# plan.json is `terraform show -json tfplan`. Imports show up as "no-op" with
# change.importing set; there's no "import" action.
#   import-only (default): only no-op / read
#   no-destroy: no "delete" anywhere, which also catches replaces
# exit 0 = ok, 1 = offenders, 2 = bad usage
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

# resource_changes is missing entirely on an empty plan
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
