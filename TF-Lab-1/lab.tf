# Create a VPC
resource "aws_vpc" "tflab" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "tflab"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.tflab.id

  tags = {
    Name = "tflab"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.tflab.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.tflab.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.tflab.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  # route {
  #   cidr_block = aws_subnet.private.cidr_block
  #   gateway_id = "local"
  # }

}

resource "aws_route_table" "privare_rt" {
  vpc_id = aws_vpc.tflab.id

  # route {
  #   cidr_block = aws_subnet.private.cidr_block
  #   gateway_id = "local"
  # }
}

resource "aws_route_table_association" "PublicSubnetRouteTableAssociation" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "PrivateSubnetRouteTableAssociation" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.privare_rt.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "Allow_SSH"
  vpc_id      = aws_vpc.tflab.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_security_group" "Allow_3000" {
  name        = "Allow_3000"
  vpc_id      = aws_vpc.tflab.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_3000" {
  security_group_id = aws_security_group.Allow_3000.id
  cidr_ipv4         = aws_vpc.tflab.cidr_block
  from_port         = 3000
  ip_protocol       = "tcp"
  to_port           = 3000
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu"]
  }
}

#Bastion
resource "aws_network_interface" "bastion" {
  subnet_id   = aws_subnet.public.id
  private_ips = ["10.0.1.100"]
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = "DEPI"

  network_interface {
    network_interface_id = aws_network_interface.bastion.id
    device_index         = 0
  }  
}

resource "aws_eip" "bar" {
  domain = "vpc"

  instance                  = aws_instance.bastion.id
  associate_with_private_ip = "10.0.1.100"
  depends_on                = [aws_internet_gateway.gw]
}

resource "aws_network_interface_sg_attachment" "sg_attachment_bastion" {
  security_group_id    = aws_security_group.allow_ssh.id
  network_interface_id = aws_instance.bastion.primary_network_interface_id
}

#Create EC2
resource "aws_network_interface" "weappb" {
  subnet_id   = aws_subnet.private.id
  private_ips = ["10.0.2.100"]
}

resource "aws_instance" "weappb" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = "DEPI"

  network_interface {
    network_interface_id = aws_network_interface.weappb.id
    device_index         = 0
  }  
}

resource "aws_network_interface_sg_attachment" "sg_attachment_ec2" {
  security_group_id    = aws_security_group.Allow_3000.id
  network_interface_id = aws_instance.weappb.primary_network_interface_id
}
