#!/usr/bin/env bash
# Stands in for the hand-built network, so envs/dev has something to import.
# No NAT gateway or Databricks here; Terraform adds those in step 2.
set -euo pipefail

ENV=${ENV:-dev}
LOCATION=${LOCATION:-eastus2}
DRY_RUN=${DRY_RUN:-0}

# keep in sync with envs/dev/locals.tf
HUB_RG="rg-hub-${ENV}"
SPOKE_RG="rg-spoke-dbx-${ENV}"
HUB_VNET="vnet-hub-${ENV}"
SPOKE_VNET="vnet-spoke-dbx-${ENV}"

# locals.tf derives these with cidrsubnet(); hardcoded here on purpose, since a
# hand-built network wouldn't have them computed either.
#   snet-shared        = cidrsubnet("10.0.0.0/22", 2, 0) = 10.0.0.0/24
#   snet-dbx-host      = cidrsubnet("10.1.0.0/22", 3, 0) = 10.1.0.0/25
#   snet-dbx-container = cidrsubnet("10.1.0.0/22", 3, 1) = 10.1.0.128/25
#   snet-workload      = cidrsubnet("10.1.0.0/22", 2, 1) = 10.1.1.0/24
HUB_CIDR="10.0.0.0/22"
SPOKE_CIDR="10.1.0.0/22"

TAGS=(--tags "environment=${ENV}")

run() {
  echo "+ $*"
  if [[ "$DRY_RUN" != "1" ]]; then
    "$@"
  fi
}

if [[ "$DRY_RUN" != "1" ]]; then
  if ! az account show -o none 2>/dev/null; then
    echo "error: not logged in to Azure. Run 'az login' (and 'az account set -s <subscription>') first." >&2
    exit 1
  fi
  echo "Subscription: $(az account show --query name -o tsv)"
fi
echo "Environment: ${ENV}  Location: ${LOCATION}"

# per subscription, and can take a few minutes on a fresh one

PROVIDERS=(Microsoft.Network Microsoft.Databricks)
for ns in "${PROVIDERS[@]}"; do
  run az provider register --namespace "$ns" -o none
done

if [[ "$DRY_RUN" != "1" ]]; then
  for ns in "${PROVIDERS[@]}"; do
    for _ in $(seq 1 60); do
      state=$(az provider show --namespace "$ns" --query registrationState -o tsv)
      echo "  ${ns}: ${state}"
      [[ "$state" == "Registered" ]] && break
      sleep 10
    done
    if [[ "$state" != "Registered" ]]; then
      echo "error: ${ns} still '${state}' after 10 minutes." >&2
      exit 1
    fi
  done
fi

# create_subnet <rg> <vnet> <subnet> <cidr> [extra az args...]
create_subnet() {
  local rg=$1 vnet=$2 subnet=$3 cidr=$4
  shift 4
  run az network nsg create -g "$rg" -n "nsg-${subnet}" -l "$LOCATION" "${TAGS[@]}" -o none
  run az network vnet subnet create -g "$rg" --vnet-name "$vnet" -n "$subnet" \
    --address-prefixes "$cidr" \
    --network-security-group "nsg-${subnet}" \
    --default-outbound false \
    "$@" -o none
}

# peering needs full IDs, the VNets are in different RGs
vnet_id() {
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "<id of $2>"
  else
    az network vnet show -g "$1" -n "$2" --query id -o tsv
  fi
}

run az group create -n "$HUB_RG" -l "$LOCATION" "${TAGS[@]}" -o none
run az network vnet create -g "$HUB_RG" -n "$HUB_VNET" -l "$LOCATION" \
  --address-prefixes "$HUB_CIDR" "${TAGS[@]}" -o none
create_subnet "$HUB_RG" "$HUB_VNET" snet-shared 10.0.0.0/24

run az group create -n "$SPOKE_RG" -l "$LOCATION" "${TAGS[@]}" -o none
run az network vnet create -g "$SPOKE_RG" -n "$SPOKE_VNET" -l "$LOCATION" \
  --address-prefixes "$SPOKE_CIDR" "${TAGS[@]}" -o none
create_subnet "$SPOKE_RG" "$SPOKE_VNET" snet-dbx-host 10.1.0.0/25 \
  --delegations Microsoft.Databricks/workspaces
create_subnet "$SPOKE_RG" "$SPOKE_VNET" snet-dbx-container 10.1.0.128/25 \
  --delegations Microsoft.Databricks/workspaces
create_subnet "$SPOKE_RG" "$SPOKE_VNET" snet-workload 10.1.1.0/24

HUB_VNET_ID=$(vnet_id "$HUB_RG" "$HUB_VNET")
SPOKE_VNET_ID=$(vnet_id "$SPOKE_RG" "$SPOKE_VNET")

run az network vnet peering create -g "$HUB_RG" --vnet-name "$HUB_VNET" \
  -n peer-hub-to-spoke-dbx --remote-vnet "$SPOKE_VNET_ID" --allow-vnet-access -o none
run az network vnet peering create -g "$SPOKE_RG" --vnet-name "$SPOKE_VNET" \
  -n peer-spoke-dbx-to-hub --remote-vnet "$HUB_VNET_ID" --allow-vnet-access -o none

echo "Done. Next: cd envs/dev && terraform init && terraform plan"
