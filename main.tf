variable "access_key_var" {
  description = "User access key for AWS"
  type = string
}

variable "secret_key_var" {
  type = string
  description = "User secret key got AWS"
}

variable "ENV" {
  type = string
  description = "Name used as a prefix to identify if resources are in production or dev"
}


# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = var.access_key_var
  secret_key = var.secret_key_var
}

# create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = format("%s-vpc", var.ENV)
  }
}

# create internet geteway 
resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = format("%s-gw", var.ENV)
  }
}

# create route table
resource "aws_route_table" "route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.prod-gw.id
    }

  tags = {
    Name = format("%s-route_table", var.ENV)
  }
}

# create subnet
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = format("%s-subnet_1", var.ENV)
  }
}

# create custom route Table association
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.route-table.id
}

# create a security group allow port 22.80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
      description      = "TLS from VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  ingress {
      description      = "HTTP"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress{
      description      = "SSH"
      from_port        = 22
      to_port          = 22
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
    Name = format("%s-security_group", var.ENV)
  }
}

# create a network interface 
resource "aws_network_interface" "web-server-nif" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  tags = {
    "Name" = format("%s-network_interface", var.ENV)
  }

}

# create elastic ip
resource "aws_eip" "lb" {
  vpc      = true
  network_interface = aws_network_interface.web-server-nif.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.prod-gw
  ]
}

output "server_public_ip" {
  value = aws_eip.lb.public_ip
}

# create Ubuntu server and install apache2
resource "aws_instance" "my-first-server" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nif.id
  }

  # bash code to install apache server
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF

  tags = {
    Name = format("%s-apache_web_server", var.ENV)
  }
}

# resource "aws_subnet" "subnet-1" {
#   vpc_id = aws_vpc.first-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#     custom = "test"
#   }
# }

# resource "aws_instance" "my-first-server" {
#   ami           = "ami-09e67e426f25ce0d7"
#   instance_type = "t2.micro"
#   tags = {
#     Name = "ubuntu"
#   }
# }