# Backend settings are supplied at init time so the same configuration can be
# pointed at a different state bucket without editing versions.tf:
#   terraform init -backend-config=backend.hcl
bucket = "asgard-landing-zone-tfstate"
region = "eu-central-1"
