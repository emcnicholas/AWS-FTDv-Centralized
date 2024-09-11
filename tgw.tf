# Provisions resources related to Transit Gateway
# All attachments for TGW utilize two subnets provisioned specifically for TGW in each VPC


# Transit Gateway
resource "aws_ec2_transit_gateway" "tgw" {
  description = "${var.env_name}-TGW"

  tags = {
    Name    = "${var.env_name}-TGW"
  }
}

# TGW Attachment to Service VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "service" {
  subnet_ids                                      = aws_subnet.service_tgw.*.id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.service.id
  transit_gateway_default_route_table_association = false
  appliance_mode_support                          = "enable"
  tags = {
    Name    = "${var.env_name}-Service-Attach"
  }
}

#TGW Attachment to Prod VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "prod" {
  subnet_ids                                      = aws_subnet.prod_tgw.*.id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.prod.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name    = "${var.env_name}-Prod-Attach"
  }
}

# TGW Attachment to Dev VPC
resource "aws_ec2_transit_gateway_vpc_attachment" "dev" {
  subnet_ids                                      = aws_subnet.dev_tgw.*.id
  transit_gateway_id                              = aws_ec2_transit_gateway.tgw.id
  vpc_id                                          = aws_vpc.dev.id
  transit_gateway_default_route_table_association = false
  tags = {
    Name    = "${var.env_name}-Dev-Attach"
  }
}

#---------------------------------------------
# TGW Route Table for Service VPC
resource "aws_ec2_transit_gateway_route_table" "service" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name    = "${var.env_name}-Service-RT"
  }
}

# TGW Route Table Service VPC Attachment
resource "aws_ec2_transit_gateway_route_table_association" "service" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.service.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.service.id
}

# Route to Prod CIDR on Service VPC Route Table
resource "aws_ec2_transit_gateway_route" "prod" {
  destination_cidr_block         = aws_vpc.prod.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.service.id
}

# Route to Dev CIDR on Service VPC Route Table
resource "aws_ec2_transit_gateway_route" "dev" {
  destination_cidr_block         = aws_vpc.dev.cidr_block
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.service.id
}

# Default gateway on Firewall Route Table points to Internet VPC Attachment
#resource "aws_ec2_transit_gateway_route" "fw_dfg" {
#  destination_cidr_block         = "0.0.0.0/0"
#  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inet.id
#  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.fw.id
#}

#-------------------------------------------------
# TGW Route Table for Spoke (Prod and Dev) VPCs. Same RT is applied to both Prod and Dev VPCs
resource "aws_ec2_transit_gateway_route_table" "spoke" {
  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
  tags = {
    Name    = "${var.env_name}-Spoke-RT"
  }
}

# TGW Route Table Prod VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "prod" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.prod.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# TGW Route Table Dev VPC Association
resource "aws_ec2_transit_gateway_route_table_association" "dev" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dev.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

# Default gateway on Spoke Route Table points to Service VPC Attachment
resource "aws_ec2_transit_gateway_route" "spoke_dfg" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.service.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.spoke.id
}

#--------------------------------------
# TGW Route Table for Internet VPCs.
#resource "aws_ec2_transit_gateway_route_table" "inet" {
#  transit_gateway_id = aws_ec2_transit_gateway.tgw.id
#  tags = {
#    Name    = "inet_tgw_rt"
#    Project = "gwlb"
#  }
#}

# TGW Route Table Internet VPC Association
#resource "aws_ec2_transit_gateway_route_table_association" "inet" {
#  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.inet.id
#  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inet.id
#}
#
## Route to FW Management Subnets on Internet Route Table points to FW VPC Attachment
#resource "aws_ec2_transit_gateway_route" "inet_fw_management" {
#  count                          = local.fw_az_count
#  destination_cidr_block         = aws_subnet.fw_management[count.index].cidr_block
#  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.fw.id
#  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inet.id
#}
#
## Default gateway on Internet Route Table points to FW VPC Attachment
#resource "aws_ec2_transit_gateway_route" "inet_dfg" {
#  destination_cidr_block         = "0.0.0.0/0"
#  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.fw.id
#  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inet.id
#}