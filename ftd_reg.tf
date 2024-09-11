#################################################
# Register FTD to FMC
#################################################

# Enable License for FMCv
resource "fmc_smart_license" "license" {
  registration_type = "EVALUATION"
}
# Create default Access Control Policy
resource "fmc_access_policies" "access_policy" {
  depends_on = [fmc_smart_license.license]
  name           = "${var.env_name}-Access-Policy"
  default_action = "block"
}

# Register AZ1 Devices to FMC
resource "fmc_devices" "ftd-cluster-1" {
  depends_on = [fmc_access_policies.access_policy]
  #count = length(var.aws_azs)
  name = local.ftd_mgmt_ips[0]
  hostname = local.ftd_mgmt_ips[0]
  regkey = var.fmc_reg_key
  nat_id = var.fmc_nat_id
  performance_tier = var.ftd_performance_tier
  license_caps = [
    "BASE",
    "MALWARE",
    "URLFilter",
    "THREAT"]
  access_policy {
    id = fmc_access_policies.access_policy.id
    type = "AccessPolicy"
    }
  cdo_host = "www.defenseorchestrator.com"
  cdo_region = var.cdo_region
}

# Register AZ2 Devices to FMC
resource "fmc_devices" "ftd-cluster-2" {
  depends_on = [fmc_devices.ftd-cluster-1]
  #count = length(var.aws_azs)
  name = local.ftd_mgmt_ips[2]
  hostname = local.ftd_mgmt_ips[2]
  regkey = var.fmc_reg_key
  nat_id = var.fmc_nat_id
  performance_tier = var.ftd_performance_tier
  license_caps = [
    "BASE",
    "MALWARE",
    "URLFilter",
    "THREAT"]
  access_policy {
    id = fmc_access_policies.access_policy.id
    type = "AccessPolicy"
    }
  cdo_host = "www.defenseorchestrator.com"
  cdo_region = var.cdo_region
}
