provider "aws" {
  region = "us-east-1"
  #access_key = "????"
  #secret_key = "???????"
}

variable "subnet1_CIDR" {
  #If no default value assgined, it will ask in terminal for input or search in .tfvars file
  description = "CIDR Subnet variable"
  #type = String
  #default = null
}

/*VPC*/
resource "aws_vpc" "VPC_Prod" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC Prod"
  }
}

/*Internet GTWY*/
resource "aws_internet_gateway" "InterGtwy" {
  vpc_id = aws_vpc.VPC_Prod.id

  tags = {
    Name = "InterGtwy"
  }
}


/*Routing table*/

resource "aws_route_table" "RouteTable" {
    vpc_id = aws_vpc.VPC_Prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.InterGtwy.id
  }

  tags = {
    Name = "RouteTable"
  }  
}

/*VPC - Subnet1*/
resource "aws_subnet" "Subnet_Prod_Public" {
  vpc_id     = aws_vpc.VPC_Prod.id
  #cidr_block = "10.0.1.0/24"
  #cidr_block = var.subnet1_CIDR[0]
  cidr_block = var.subnet1_CIDR[0].cidr_block
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet1_CIDR[0].name
  }

}

/*VPC - Subnet2*/
resource "aws_subnet" "Subnet_Prod_Public2" {
  vpc_id     = aws_vpc.VPC_Prod.id
  #cidr_block = "10.0.1.0/24"
  #cidr_block = var.subnet1_CIDR[1]
  cidr_block = var.subnet1_CIDR[1].cidr_block
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet1_CIDR[1].name
  }

}

/*Assign route table to subnet*/
resource "aws_route_table_association" "RouteTableAsocc" {
  subnet_id      = aws_subnet.Subnet_Prod_Public.id
  route_table_id = aws_route_table.RouteTable.id
}


/*Security Group*/
resource "aws_security_group" "SecGroup-1" {
  vpc_id = aws_vpc.VPC_Prod.id
  name = "allow_web_traffic"
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

/* Create Ubuntu server and install/enable apache2 */

resource "aws_instance" "Instance1" {
  subnet_id         = aws_subnet.Subnet_Prod_Public.id
  ami               = "ami-085925f297f89fce1"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1a"
  associate_public_ip_address = true
  key_name          = "MainKey"
  vpc_security_group_ids = [aws_security_group.SecGroup-1.id]

  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
  tags = {
    Name = "web-server"
  }
}