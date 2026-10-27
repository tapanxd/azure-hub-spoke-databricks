# Local equivalents of the CI jobs. `make check` runs everything that needs no Azure access.
# Recipes start with ">" instead of a tab.
.RECIPEPREFIX = >
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

MODULES := modules/vnet modules/peering modules/databricks-workspace
ROOTS   := $(MODULES) envs/dev

.PHONY: fmt fmt-check init validate lint test scripts-test check

fmt:
> terraform fmt -recursive

fmt-check:
> terraform fmt -check -recursive

init:
> for d in $(ROOTS); do \
>   echo "== init $$d"; \
>   terraform -chdir=$$d init -backend=false -input=false -no-color >/dev/null; \
> done

validate: init
> for d in $(ROOTS); do \
>   echo "== validate $$d"; \
>   terraform -chdir=$$d validate -no-color; \
> done

lint:
> tflint --init --config "$(CURDIR)/.tflint.hcl"
> tflint --recursive --config "$(CURDIR)/.tflint.hcl"

test: init
> for d in $(ROOTS); do \
>   echo "== test $$d"; \
>   terraform -chdir=$$d test -no-color; \
> done

scripts-test:
> scripts/test-assert-plan.sh

check: fmt-check validate lint test scripts-test
> @echo "All checks passed."
