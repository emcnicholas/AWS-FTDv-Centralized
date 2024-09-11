# Provisions FTD firewalls in Firewall VPC
# Multiple firewalls are provisioned in each firewall AZ based on the count set in variables
data "aws_ami" "ftdv_7_4" {
  most_recent = true
  owners      = ["679593333241"]
  filter {
    name   = "name"
    values = ["ftdv-7.3*"]
  }
  filter {
    name   = "product-code"
    values = ["a8sxy6easi2zumgtyr564z6y7"]
  }
}

# Management interfaces
resource "aws_network_interface" "ftd_management" {
  count           = length(var.aws_azs) * var.fw_per_az
  description     = "ftd_management_if-${count.index + 1}"
  subnet_id       = aws_subnet.fw_management[floor(count.index / var.fw_per_az)].id
  security_groups = [aws_security_group.service-sg.id]
  tags = {
    Name    = "${var.env_name}-FTD-Mgmt-Int-${count.index + 1}"
  }
}

# Diagnostic interfaces
resource "aws_network_interface" "ftd_diagnostic" {
  count           = length(var.aws_azs) * var.fw_per_az
  description     = "ftd_diagnstic_if-${count.index + 1}"
  subnet_id       = aws_subnet.fw_management[floor(count.index / var.fw_per_az)].id
  security_groups = [aws_security_group.service-sg.id]
  tags = {
    Name    = "${var.env_name}-FTD-Diag-Int-${count.index + 1}"
  }
}

# Data interfaces
resource "aws_network_interface" "ftd_data" {
  count             = length(var.aws_azs) * var.fw_per_az
  description       = "ftd_data_if-${count.index + 1}"
  subnet_id         = aws_subnet.fw_data[floor(count.index / var.fw_per_az)].id
  security_groups   = [aws_security_group.service-sg.id]
  source_dest_check = false
  tags = {
    Name    = "${var.env_name}-FTD-Data-Int-${count.index + 1}"
  }
}

# CCL interfaces
resource "aws_network_interface" "ftd_ccl" {
  count             = length(var.aws_azs) * var.fw_per_az
  description       = "ftd_ccl_if-${count.index + 1}"
  subnet_id         = aws_subnet.fw_ccl[floor(count.index / var.fw_per_az)].id
  security_groups   = [aws_security_group.service-sg.id]
  source_dest_check = false
  tags = {
    Name    = "${var.env_name}-FTD-CCL-Int-${count.index + 1}"
  }
}

# FTD Firewalls
resource "aws_instance" "ftd" {
  depends_on = [aws_instance.fmcv]
  count                       = length(var.aws_azs) * var.fw_per_az
  ami                         = data.aws_ami.ftdv_7_4.id
  instance_type               = "c5.xlarge"
  key_name                    = aws_key_pair.public_key.key_name
  user_data_replace_on_change = true
  user_data                   = <<-EOT
  {
    "AdminPassword": "123Cisco@123!",
    "Hostname": "ftd-${count.index + 1}",
    "FirewallMode": "Routed",
    "ManageLocally": "No",
    "FmcIp": "${aws_instance.fmcv.private_ip}",
    "FmcRegKey":"${var.fmc_reg_key}",
    "FmcNatId":"${var.fmc_nat_id}",
    "Cluster": {
      "CclSubnetRange": "${cidrhost(cidrsubnet(aws_vpc.service.cidr_block, 8, 16), 1 + 16 * floor(count.index / var.fw_per_az))} ${cidrhost(cidrsubnet(aws_vpc.service.cidr_block, 8, 16), 14 + 16 * floor(count.index / var.fw_per_az))}",
      "ClusterGroupName": "ftd_cluster-${floor(count.index / var.fw_per_az) + 1}",
      "Geneve": "Yes",
      "HealthProbePort": "12345"
    }
  }
  EOT

  network_interface {
    network_interface_id = aws_network_interface.ftd_management[count.index].id
    device_index         = 0
  }
  network_interface {
    network_interface_id = aws_network_interface.ftd_diagnostic[count.index].id
    device_index         = 1
  }
  network_interface {
    network_interface_id = aws_network_interface.ftd_data[count.index].id
    device_index         = 2
  }
  network_interface {
    network_interface_id = aws_network_interface.ftd_ccl[count.index].id
    device_index         = 3
  }
  tags = {
    Name    = "${var.env_name}-FTD-${count.index + 1}"
  }
}

locals {
  ftd_mgmt_ips = [for instance in aws_instance.ftd : instance.private_ip]
}
