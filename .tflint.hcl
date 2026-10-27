# Run from the repo root with: tflint --recursive --config "$(pwd)/.tflint.hcl"
# (with --recursive, a relative --config path is resolved per directory).

config {
  # Follow local module calls (../../modules/*) when linting envs/dev.
  call_module_type = "local"
}

# Bundled with tflint: typed variables, required_version and required_providers
# with version constraints, unused declarations, deprecated syntax.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# Not in the recommended preset, but this repo's convention is that every
# variable and output has a description.
rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}
