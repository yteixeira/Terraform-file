provider "aws" {
  region = "eu-west-1"
}
resource "aws_instance" "app_instance" {
  ami                         = "${var.app_ami_id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.app_security_group.id}"]
  subnet_id                   = "${aws_subnet.app_private_subnet.id}"
  user_data                   = "${data.template_file.app_init.rendered}"
  tags = {
    Name = "${var.name}_terraform_lesson"
  }
}
resource "aws_instance" "db_instance" {
  ami                         = "${var.db_ami_id}"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["${aws_security_group.app_security_group.id}"]
  subnet_id                   = "${aws_subnet.app_private_subnet.id}"
  tags = {
    Name = "${var.db-name}_db_terraform_lesson"
  }
}
resource "aws_security_group" "app_security_group" {
  name        = "${var.name}_security_group"
  description = "Allow inbound traffic"
  vpc_id      = "${var.vpc_id}"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}_security_group"
  }
}
resource "aws_security_group" "db_security_group" {
  name        = "${var.db-name}_security_group"
  description = "Allow inbound traffic"
  vpc_id      = "${var.vpc_id}"

  egress {
    from_port = 3000
    to_port   = 27017
    protocol  = "-1"
  }
  tags = {
    Name = "${var.db-name}_security_group"
  }
}

resource "aws_subnet" "app_private_subnet" {
  vpc_id     = "${var.vpc_id}"
  cidr_block = "10.0.20.0/24"
  tags = {
    Name = "${var.name}_subnet_private"
  }
}
resource "aws_subnet" "db_private_subnet" {
  vpc_id     = "${var.vpc_id}"
  cidr_block = "10.0.21.0/24"
  tags = {
    Name = "${var.db-name}_private"
  }
}
resource "aws_route_table" "app_route_table" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${data.aws_internet_gateway.default.id}"
  }

  tags = {
    Name = "${var.name}_route_table"
  }
}
resource "aws_route_table_association" "app_assos" {
  subnet_id      = "${aws_subnet.app_private_subnet.id}"
  route_table_id = "${aws_route_table.app_route_table.id}"
}

data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = ["${var.vpc_id}"]
  }
}
data "template_file" "app_init" {
  template = "${file("./scripts/app/init.sh.tpl")}"
  vars = {
    db_host = "mongodb://${aws_instance.db_instance.private_ip}:27017/posts"
  }
}
