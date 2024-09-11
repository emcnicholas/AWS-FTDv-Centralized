# Gateway Load Balancing related resources
resource "aws_lb" "gwlb" {
  name                             = "${var.env_name}-GWLB"
  load_balancer_type               = "gateway"
  subnets                          = aws_subnet.fw_data.*.id
  enable_cross_zone_load_balancing = false

  tags = {
    Name    = "${var.env_name}-GWLB"
  }
}

# Target group is IP based since FTD's are provisioned with multiple interfaces
resource "aws_lb_target_group" "ftd" {
  name        = "ftdtg"
  protocol    = "GENEVE"
  vpc_id      = aws_vpc.service.id
  target_type = "ip"
  port        = 6081
  stickiness {
    type = "source_ip_dest_ip"
  }
  health_check {
    port     = 12345
    protocol = "TCP"
  }
}

# Target group is attached to IP addresss of data interfaces
resource "aws_lb_target_group_attachment" "ftd" {
  count            = length(var.aws_azs) * var.fw_per_az
  target_group_arn = aws_lb_target_group.ftd.arn
  target_id        = aws_network_interface.ftd_data[count.index].private_ip
}

# GWLB Listener
resource "aws_lb_listener" "cluster" {
  load_balancer_arn = aws_lb.gwlb.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ftd.arn
  }
}

# Endpoint Service
resource "aws_vpc_endpoint_service" "gwlb" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
  tags = {
    Name    = "${var.env_name}-GWLB-EP-Service"
  }
}

# GWLB Endpoints. One is required for each AZ in App1 VPC
resource "aws_vpc_endpoint" "fw_data" {
  count             = length(var.aws_azs)
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  vpc_endpoint_type = aws_vpc_endpoint_service.gwlb.service_type
  vpc_id            = aws_vpc.service.id
  tags = {
    Name    = "${var.env_name}-GWLBe-${count.index + 1}"
  }
}

# Delay after GWLB Endpoint creation
resource "time_sleep" "fw_data" {
  create_duration = "180s"
  depends_on = [
    aws_vpc_endpoint.fw_data
  ]
}

# GWLB Endpoints are placed in FW Data subnets in Firewall VPC
resource "aws_vpc_endpoint_subnet_association" "fw" {
  count           = length(var.aws_azs)
  vpc_endpoint_id = aws_vpc_endpoint.fw_data[count.index].id
  subnet_id       = aws_subnet.fw_data[count.index].id
}