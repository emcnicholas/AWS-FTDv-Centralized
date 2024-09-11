# One NAT GW is provisioned per AZ
resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.aws_azs)
  allocation_id = aws_eip.nat_gw[count.index].id
  subnet_id     = aws_subnet.inet_natgw[count.index].id
  depends_on    = [aws_internet_gateway.inet_gw]
  tags = {
    Name    = "${var.env_name}-NAT_GW-${count.index + 1}"
  }
}

# Public IP of the NAT Gateway
resource "aws_eip" "nat_gw" {
  count = length(var.aws_azs)
}

# Internet Gateway is required for NAT Gateway to be able to reach the Internet
resource "aws_internet_gateway" "inet_gw" {
  vpc_id = aws_vpc.service.id
}