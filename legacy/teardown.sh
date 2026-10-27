#!/usr/bin/env bash
# Deletes both resource groups. The managed databricks-rg-* group is cleaned
# up by Databricks after the workspace goes; last time that lagged a while.
#
# `terraform destroy` in envs/dev is the cleaner option once everything is in
# state. This one also works when the state is missing or half-done.
#
#   ENV=dev legacy/teardown.sh
set -euo pipefail

ENV=${ENV:-dev}
RGS=("rg-spoke-dbx-${ENV}" "rg-hub-${ENV}")

if ! az account show -o none 2>/dev/null; then
  echo "error: not logged in to Azure. Run 'az login' first." >&2
  exit 1
fi

echo "Subscription: $(az account show --query name -o tsv)"
echo "This permanently deletes these resource groups and everything in them:"
printf '  %s\n' "${RGS[@]}"
read -r -p "Type the environment name (${ENV}) to confirm: " answer
if [[ "$answer" != "$ENV" ]]; then
  echo "Aborted."
  exit 1
fi

# spoke first, it's the slow one
for rg in "${RGS[@]}"; do
  if [[ "$(az group exists -n "$rg")" == "true" ]]; then
    echo "Deleting ${rg} (this can take several minutes)..."
    az group delete -n "$rg" --yes
  else
    echo "${rg} does not exist, skipping."
  fi
done

echo "Done. If envs/dev has local state, delete envs/dev/terraform.tfstate* as well."
