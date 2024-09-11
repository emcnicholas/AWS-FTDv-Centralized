#########################
# Prod VPC
#########################
resource "aws_vpc" "prod" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.env_name}-Prod-VPC"
  }
}

# One App subnet in each AZ for Prod VPC
resource "aws_subnet" "prod_app" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.prod.id
  cidr_block        = cidrsubnet(aws_vpc.prod.cidr_block, 8, 1 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-Prod-App-Subnet-${count.index + 1}"
  }
}

# One TGW subnet in each AZ for Prod VPC
resource "aws_subnet" "prod_tgw" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.prod.id
  cidr_block        = cidrsubnet(aws_vpc.prod.cidr_block, 8, 11 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-Prod-TGW-Subnet-${count.index + 1}"
  }
}

#######################
# Dev VPC
#######################
resource "aws_vpc" "dev" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.env_name}-Dev-VPC"
  }
}

# One App subnet in each AZ for Dev VPC
resource "aws_subnet" "dev_app" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.dev.id
  cidr_block        = cidrsubnet(aws_vpc.dev.cidr_block, 8, 1 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-Dev-App-Subnet-${count.index + 1}"
  }
}

# One TGW subnet in each AZ for Dev VPC
resource "aws_subnet" "dev_tgw" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.dev.id
  cidr_block        = cidrsubnet(aws_vpc.dev.cidr_block, 8, 11 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-Dev-TGW-Subnet-${count.index + 1}"
  }
}

###########################
# Service VPC
###########################
resource "aws_vpc" "service" {
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name    = "${var.env_name}-Service-VPC"
  }
}

# Subnets for Firewall management Interfaces
resource "aws_subnet" "fw_management" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.service.id
  cidr_block        = cidrsubnet(aws_vpc.service.cidr_block, 8, 1 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-FW-Mgmt-Subnet-${count.index + 1}"
  }
}

# Subnets for Firewall data Interfaces
resource "aws_subnet" "fw_data" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.service.id
  cidr_block        = cidrsubnet(aws_vpc.service.cidr_block, 8, 5 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-FW-Data-Subnet-${count.index + 1}"
  }
}

# Subnets for Firewall CCL Interfaces.
# Since we have to specify the range of IP addresses for CCL link, keeping this subnet small: /28
# The caculation below will generate 10.x.16.0/28,10.x.16.16/28, 10.x.16.32/28, etc.
resource "aws_subnet" "fw_ccl" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.service.id
  cidr_block        = cidrsubnet(aws_vpc.service.cidr_block, 12, 256 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-FW-CCL-Subnet-${count.index + 1}"
  }
}

# One TGW subnet in each AZ for Service VPC
resource "aws_subnet" "service_tgw" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.service.id
  cidr_block        = cidrsubnet(aws_vpc.service.cidr_block, 8, 11 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-Service-TGW-Subnet-${count.index + 1}"
  }
}

# Subnets for NAT Gateways in Service VPC
resource "aws_subnet" "inet_natgw" {
  count             = length(var.aws_azs)
  vpc_id            = aws_vpc.service.id
  cidr_block        = cidrsubnet(aws_vpc.service.cidr_block, 8, 21 + count.index)
  availability_zone = var.aws_azs[count.index]
  tags = {
    Name    = "${var.env_name}-Service-NGW-Subnet-${count.index + 1}"
  }
}

# Subnets for FMCv in Service VPC
resource "aws_subnet" "fmc_mgmt" {
  #count             = length(var.aws_azs)
  vpc_id            = aws_vpc.service.id
  cidr_block        = cidrsubnet(aws_vpc.service.cidr_block, 8, 31)
  availability_zone = var.aws_azs[0]
  tags = {
    Name    = "${var.env_name}-FMC_Mgmt-Subnet"
  }
}

# Generic Security Group for all access for Service VPC
resource "aws_security_group" "service-sg" {
  vpc_id = aws_vpc.service.id
  name   = "${var.env_name}-Service-SG"
  tags = {
    Name    = "${var.env_name}-Service-SG"
  }
  egress = [
    {
      description      = "Allow all outbound"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  ingress = [
    {
      description      = "Allow all inbound"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

# Generic Security Group for all access for Prod VPC
resource "aws_security_group" "prod-sg" {
  vpc_id = aws_vpc.prod.id
  name   = "${var.env_name}-Prod-SG"
  tags = {
    Name    = "${var.env_name}-Service-SG"
  }
  egress = [
    {
      description      = "Allow all outbound"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  ingress = [
    {
      description      = "Allow all inbound"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}

# Generic Security Group for all access for Dev VPC
resource "aws_security_group" "dev-sg" {
  vpc_id = aws_vpc.dev.id
  name   = "${var.env_name}-Dev-SG"
  tags = {
    Name    = "${var.env_name}-Dev-SG"
  }
  egress = [
    {
      description      = "Allow all outbound"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  ingress = [
    {
      description      = "Allow all inbound"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}