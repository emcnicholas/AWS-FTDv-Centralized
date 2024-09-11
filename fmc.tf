# FMC

# Query the ASW Marketplace for FMC AMI
data "aws_ami" "fmcv" {
  most_recent = true
  owners   = ["aws-marketplace"]

 filter {
    name   = "name"
    values = ["fmcv-7.4*"]
  }

  filter {
    name   = "product-code"
    values = ["bhx85r4r91ls2uwl69ajm9v1b"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# FMCv Mgmt Interface
resource "aws_network_interface" "fmcmgmt" {
  depends_on    = [aws_subnet.fmc_mgmt]
  description   = "fmc-mgmt"
  subnet_id     = aws_subnet.fmc_mgmt.id
  tags = {
    Name = "${var.env_name} FMC-1 Mgmt"
  }
}
# Attach Security Group to FMC Management Interface
resource "aws_network_interface_sg_attachment" "fmc_mgmt_attachment" {
  depends_on           = [aws_network_interface.fmcmgmt]
  security_group_id    = aws_security_group.service-sg.id
  network_interface_id = aws_network_interface.fmcmgmt.id
}

# Deploy FMCv Instance in AWS
resource "aws_instance" "fmcv" {
  ami                 = data.aws_ami.fmcv.id
  instance_type       = "c5.4xlarge"
  key_name            = aws_key_pair.public_key.key_name
  availability_zone   = var.aws_azs[0]
  network_interface {
    network_interface_id = aws_network_interface.fmcmgmt.id
    device_index         = 0
  }
  user_data = <<-EOT
  {
   "AdminPassword":"123Cisco@123!",
   "Hostname":"FMC-1"
  }
  EOT

  tags = {
    Name = "${var.env_name}_FMCv"
  }
}

# FMC Mgmt Elastic IP
resource "aws_eip" "fmcmgmt-EIP" {
  depends_on = [aws_internet_gateway.inet_gw]
  tags = {
    "Name" = "${var.env_name} FMCv Management IP"
  }
}

# Assocaite FMC Management Interface to External IP
resource "aws_eip_association" "fmc-mgmt-ip-assocation" {
  network_interface_id = aws_network_interface.fmcmgmt.id
  allocation_id        = aws_eip.fmcmgmt-EIP.id
}