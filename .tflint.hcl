# --recursive resolves a relative --config per directory, so pass an absolute path:
#   tflint --recursive --config "$(pwd)/.tflint.hcl"

config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

# not in the recommended preset, despite what I assumed
rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}
