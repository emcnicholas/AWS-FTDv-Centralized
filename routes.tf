# VPC Route Tables and Routes

# Spoke VPC Routes
# Default gateway on Prod Route Table pointing to Transit Gateway
resource "aws_route" "prod_dfgw" {
  depends_on = [aws_ec2_transit_gateway.tgw]
  route_table_id         = aws_vpc.prod.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Default gateway on Dev Route Table pointing to Transit Gateway
resource "aws_route" "dev_dfgw" {
  depends_on = [aws_ec2_transit_gateway.tgw]
  route_table_id         = aws_vpc.dev.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = aws_ec2_transit_gateway.tgw.id
}

# Service VPC Route Table for FW Mgmt subnets
resource "aws_route_table" "fw_management" {
  count = length(var.aws_azs)
  vpc_id = aws_vpc.service.id
  tags = {
    Name = "${var.env_name}-FW_Mgmt-RT-${count.index + 1}"
  }
}

# Association to Firewall management subnets
resource "aws_route_table_association" "fw_management" {
  count          = length(var.aws_azs)
  subnet_id      = aws_subnet.fw_management[count.index].id
  route_table_id = aws_route_table.fw_management[count.index].id
}

# Default gateway on FW Mgmt Route Table pointing to NAT Gateway
resource "aws_route" "fw_dfgw" {
  depends_on = [aws_nat_gateway.nat_gw]
  count                  = length(var.aws_azs)
  route_table_id         = aws_route_table.fw_management[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id
}

## Routes in FW mgmt Route Table for Prod CIDR point to TGW
#resource "aws_route" "fw_mgmt_prod" {
#  count = length(var.aws_azs)
#  route_table_id = aws_route_table.fw_management[count.index].id
#  destination_cidr_block = aws_vpc.prod.cidr_block
#  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
#}
#
## Routes in FW mgmt Route Table for Dev CIDR point to TGW
#resource "aws_route" "fw_mgmt_dev" {
#  count = length(var.aws_azs)
#  route_table_id = aws_route_table.fw_management[count.index].id
#  destination_cidr_block = aws_vpc.dev.cidr_block
#  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
#}

# FW Data
# Service VPC Route Table for FW Data subnets
resource "aws_route_table" "fw_data" {
  count = length(var.aws_azs)
  vpc_id    = aws_vpc.service.id
  tags = {
    Name    = "${var.env_name}-FW_Data-RT-${count.index + 1}"
  }
}

# Association to fw data subnets
resource "aws_route_table_association" "fw_data" {
  count          = length(var.aws_azs)
  subnet_id      = aws_subnet.fw_data[count.index].id
  route_table_id = aws_route_table.fw_data[count.index].id
}

# Default gateway on FW Data Route Table pointing to NAT Gateway
resource "aws_route" "fw_data_dfgw" {
  depends_on = [aws_nat_gateway.nat_gw]
  count = length(var.aws_azs)
  route_table_id         = aws_route_table.fw_data[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index].id
}

# Routes in FW Data Route Table for Prod CIDR point to TGW
resource "aws_route" "fw_data_prod" {
  depends_on = [aws_ec2_transit_gateway.tgw]
  count = length(var.aws_azs)
  route_table_id = aws_route_table.fw_data[count.index].id
  destination_cidr_block = aws_vpc.prod.cidr_block
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
}

# Routes in FW Data Route Table for Dev CIDR point to TGW
resource "aws_route" "fw_data_dev" {
  depends_on = [aws_ec2_transit_gateway.tgw]
  count = length(var.aws_azs)
  route_table_id = aws_route_table.fw_data[count.index].id
  destination_cidr_block = aws_vpc.dev.cidr_block
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
}

# Service VPC for Service TGW Route Table
resource "aws_route_table" "service_tgw" {
  count  = length(var.aws_azs)
  vpc_id = aws_vpc.service.id
  tags = {
    Name    = "${var.env_name}-Service_TGW-RT-${count.index + 1}"
  }
}

# Association to Service TGW subnets
resource "aws_route_table_association" "service_tgw" {
  count          = length(var.aws_azs)
  subnet_id      = aws_subnet.service_tgw[count.index].id
  route_table_id = aws_route_table.service_tgw[count.index].id
}

# Default gateway on Service TGW Route Table pointing to GWLB endpoint
resource "aws_route" "fw_tgw_dfgw" {
  depends_on = [aws_vpc_endpoint.fw_data, time_sleep.fw_data]
  count                  = length(var.aws_azs)
  route_table_id         = aws_route_table.service_tgw[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.fw_data[count.index].id
}

# --------------------------------------------------
# Route tables for traffic from NAT Gateways
resource "aws_route_table" "natgw" {
  count  = length(var.aws_azs)
  vpc_id = aws_vpc.service.id
  tags = {
    Name    = "${var.env_name}-NatGW-RT-${count.index + 1}"
  }
}

resource "aws_route_table_association" "inet_natgw" {
  count          = length(var.aws_azs)
  subnet_id      = aws_subnet.inet_natgw[count.index].id
  route_table_id = aws_route_table.natgw[count.index].id
}

# Default routes on NAT GW route tables in Internet VPC point to Internet Gateway
resource "aws_route" "inet_natgw_dfgw" {
  depends_on = [aws_internet_gateway.inet_gw]
  count                  = length(var.aws_azs)
  route_table_id         = aws_route_table.natgw[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inet_gw.id
}

# Routes in NAT GW route table for Prod CiDR block point to GWLB
resource "aws_route" "inet_prod" {
  depends_on = [aws_vpc_endpoint.fw_data]
  count                  = length(var.aws_azs)
  route_table_id         = aws_route_table.natgw[count.index].id
  destination_cidr_block = aws_vpc.prod.cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.fw_data[count.index].id
}

# Routes in NAT GW route table for Dev CiDR block point to GWLB
resource "aws_route" "inet_dev" {
  depends_on = [aws_vpc_endpoint.fw_data]
  count                  = length(var.aws_azs)
  route_table_id         = aws_route_table.natgw[count.index].id
  destination_cidr_block = aws_vpc.dev.cidr_block
  vpc_endpoint_id        = aws_vpc_endpoint.fw_data[count.index].id
}

# Service VPC Route Table for FMC Mgmt subnet
resource "aws_route_table" "fmc_mgmt" {
  vpc_id = aws_vpc.service.id
  tags = {
    Name = "${var.env_name}-FMC_Mgmt-RT"
  }
}

# Association to FMC management subnet
resource "aws_route_table_association" "fmc_mgmt" {
  subnet_id      = aws_subnet.fmc_mgmt.id
  route_table_id = aws_route_table.fmc_mgmt.id
}

# Default gateway on FMC Mgmt Route Table pointing to Internet Gateway
resource "aws_route" "fmc_dfgw" {
  depends_on = [aws_internet_gateway.inet_gw]
  route_table_id         = aws_route_table.fmc_mgmt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.inet_gw.id
}

# Routes in FMC mgmt Route Table for Prod CIDR point to TGW
resource "aws_route" "fmc_mgmt_prod" {
  depends_on = [aws_ec2_transit_gateway.tgw]
  route_table_id = aws_route_table.fmc_mgmt.id
  destination_cidr_block = aws_vpc.prod.cidr_block
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
}

# Routes in FMC mgmt Route Table for Dev CIDR point to TGW
resource "aws_route" "fmc_mgmt_dev" {
  depends_on = [aws_ec2_transit_gateway.tgw]
  route_table_id = aws_route_table.fmc_mgmt.id
  destination_cidr_block = aws_vpc.dev.cidr_block
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
}
