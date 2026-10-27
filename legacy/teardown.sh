#!/usr/bin/env bash
# Deletes everything bootstrap.sh and Terraform created: the hub and spoke
# resource groups. Deleting the spoke group also deletes the Databricks
# workspace, which in turn removes its managed resource group.
#
# Usage: ENV=dev legacy/teardown.sh
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

# Spoke first: it holds the workspace and NAT gateway.
for rg in "${RGS[@]}"; do
  if [[ "$(az group exists -n "$rg")" == "true" ]]; then
    echo "Deleting ${rg} (this can take several minutes)..."
    az group delete -n "$rg" --yes
  else
    echo "${rg} does not exist, skipping."
  fi
done

echo "Done. If envs/dev has local state, delete envs/dev/terraform.tfstate* as well."
