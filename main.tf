resource "aws_vpc" "vpc" {
  cidr_block           = var.main_network
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name      = "${var.project_name}-${var.project_env}"
    "Project" = var.project_name
    "Env"     = var.project_env
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name      = "${var.project_name}-${var.project_env}"
    "Project" = var.project_name
    "Env"     = var.project_env
  }
}
resource "aws_subnet" "private" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.main_network, 3, "${count.index + 3}")
  map_public_ip_on_launch = false
  availability_zone       = "${var.region}a"

  tags = {
    Name      = "${var.project_name}-${var.project_env}-private-${count.index + 1}"
    "Project" = var.project_name
    "Env"     = var.project_env
  }
}
resource "aws_subnet" "public" {
  count                   = 3
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.main_network, 3, "${count.index}")
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"

  tags = {
    Name      = "${var.project_name}-${var.project_env}-public-${count.index + 1}"
    "Project" = var.project_name
    "Env"     = var.project_env
  }
}

resource "aws_eip" "nat-gateway" {

  domain = "vpc"
  tags = {
    Name      = "${var.project_name}-${var.project_env}-nat-gateway"
    "Project" = var.project_name
    "Env"     = var.project_env
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  allocation_id = aws_eip.nat-gateway.id
  subnet_id     = aws_subnet.public.1.id

  tags = {
    Name      = "${var.project_name}-${var.project_env}-nat-gateway"
    "Project" = var.project_name
    "Env"     = var.project_env
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "${var.project_name}-${var.project_env}-route-public"
    "Project" = var.project_name
    "Env"     = var.project_env
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }

  tags = {
    Name      = "${var.project_name}-${var.project_env}-route-private"
    "Project" = var.project_name
    "Env"     = var.project_env
  }
}
resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
resource "aws_security_group" "Uber-Frontend" {
  name        = "${var.project_name}-${var.project_env}-Frontend"
  description = "Uber-Frontend-SG"
  vpc_id      = aws_vpc.vpc.id


  ingress {

    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  ingress {

    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {

    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name      = "${var.project_name}-${var.project_env}-frontend"
    "Project" = var.project_name
    "Env"     = var.project_env
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "Wordpress-Frontend" {
  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public[1].id
  user_data = file("userdata.sh")

  key_name               = "DevOps"
  vpc_security_group_ids = [aws_security_group.Uber-Frontend.id]
  tags = { "Name" = "${var.project_name}-${var.project_env}-Frontend",
    "Project" = var.project_name,
    "Env"     = var.project_env,

  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "webserver" {
  instance = aws_instance.Wordpress-Frontend.id
  domain   = "vpc"
}

resource "aws_route53_record" "frontend" {
  zone_id = "Z055360718SDDQS3K8J5J"
  name    = "git.jijinmichael.online"
  type    = "A"
  ttl     = 10
  records = [aws_eip.webserver.public_ip]
}
