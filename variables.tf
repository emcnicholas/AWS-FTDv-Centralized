###################################
# Environment Variables
###################################

variable "env_name" {
  description = "Name of the environment"
}

variable "app_name" {
  default = "app"
}
variable "app1_name" {
  default = "app1"
}

variable "app2_name" {
  default = "app2"
}

# Number of firewalls in each AZ
variable "fw_per_az" {
  default = 2
}

############################
# AWS Variables
############################

variable "aws_access_key" {
  type = string
  sensitive = true
}
variable "aws_secret_key" {
  type = string
  sensitive = true
}
variable "region" {
  type = string
  default = "us-east-1"
}

variable "aws_az1" {
  type = string
  default = "us-east-1a"
}

variable "aws_az2" {
  type = string
  default = "us-east-1b"
}

variable "aws_azs" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "ssh_key" {
  default = "ftd_key"
}

#################################
# Cisco Secure Firewall Variables
#################################

variable "FTD_version" {
  type = string
  default = "ftdv-7.4.2-172"
}

variable "cdFMC" {
  type = string
}

variable "cdo_token" {
  type = string
  sensitive = true
}

variable "cdfmc_domain_uuid" {
  type = string
  default = "e276abec-e0f2-11e3-8169-6d9ed49b625f"
}

variable "cdo_region" {
  description = "us, eu, apj"
  default = "us"
}

variable "ftd_pass" {
  type = string
  sensitive = true
}

variable "ftd_hostname" {
  type = string
  default = "FTD1"
}

variable "fmc_reg_key" {
  sensitive = true
}
variable "fmc_nat_id" {
  sensitive = true
}
variable "ftd_performance_tier" {
  default = "FTDv30"
}

variable "fmc_insecure_skip_verify" {
    type = bool
    default = true
}

# Instance Variables

variable "inbound_ports" {
  description = "Inbound Ports"
  type = list
  default = [443, 22, 8080, 8081]
}
variable "instance_type" {
  description = "Instance type"
  type = string
  default = "c5.2xlarge"
}
variable "volume_size" {
  description = "Instance volume size in GB"
  type        = number
  default     = 40
}
