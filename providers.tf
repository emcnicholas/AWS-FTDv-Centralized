###################################
# Providers
###################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    fmc = {
      source = "CiscoDevNet/fmc"
      version = ">=1.2.4"
    }
  }
}

provider "aws" {
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
    region     =  var.region
}

# FMCv
provider "fmc" {
  fmc_username = "admin"
  fmc_password = "123Cisco@123!"
  fmc_host = aws_instance.fmcv.public_ip
  fmc_insecure_skip_verify = var.fmc_insecure_skip_verify
}

## cdFMC
#provider "fmc" {
#  is_cdfmc  = true
#  cdo_token = var.cdo_token
#  fmc_host  = var.cdFMC
#  cdfmc_domain_uuid = var.cdfmc_domain_uuid
#}

