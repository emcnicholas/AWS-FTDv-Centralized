# Provisions test Amazon Linux Instances

data "aws_ami" "ami_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Instances in App1 VPC
resource "aws_instance" "prod_app1_linux" {
  count         = 2
  ami           = data.aws_ami.ami_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.public_key.key_name
  subnet_id     = aws_subnet.prod_app[count.index].id
  vpc_security_group_ids = [
    aws_security_group.prod-sg.id,
  ]
  tags = {
    Name    = "${var.env_name}-prod_app1_linux_${count.index + 1}"
  }
}

# Instances in App2 VPC
resource "aws_instance" "dev_app1_linux" {
  count         = 2
  ami           = data.aws_ami.ami_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.public_key.key_name
  subnet_id     = aws_subnet.dev_app[count.index].id
  vpc_security_group_ids = [
    aws_security_group.dev-sg.id
  ]
  tags = {
    Name    = "${var.env_name}-dev_app1_linux_${count.index + 1}"
  }
}

# Instances in Jumphost
resource "aws_instance" "jumphost_linux" {
  ami           = data.aws_ami.ami_linux.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.public_key.key_name
  subnet_id     = aws_subnet.fmc_mgmt.id
  associate_public_ip_address = true
  vpc_security_group_ids = [
    aws_security_group.service-sg.id
  ]
  tags = {
    Name    = "${var.env_name}-jumphost_linux"
  }
}

resource "local_file" "lab_info" {
  depends_on = [aws_instance.fmcv,aws_instance.ftd,aws_instance.jumphost_linux]
    content     = <<-EOT
    FMC URL  = https://${aws_instance.fmcv.public_dns}
    Jump SSH  = ssh -i "${local_file.this.filename}" ec2-user@${aws_instance.jumphost_linux.public_dns}
    EOT

    filename = "${path.module}/lab_info.txt"
}