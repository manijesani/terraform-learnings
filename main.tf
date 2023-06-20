provider "aws" {
    region = "us-east-1"
}
variable "vpc_cidr_blocks" {}
variable "subnet_cidr_blocks" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}
variable "private_key_location" {}
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.vpc_cidr_blocks
    tags = {
      Name = "${var.env_prefix}-vpc"
    }
  
}
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    availability_zone = var.avail_zone
    cidr_block = var.subnet_cidr_blocks
    tags = {
        Name = "${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
      Name = "${var.env_prefix}-igw"
    }
}

resource "aws_route_table" "myapp-rote-table" {
    vpc_id = aws_vpc.myapp-vpc.id
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
      Name = "${var.env_prefix}-rtw"
    }
  
}

resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-rote-table.id
}

resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id
    
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip]
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []

    }
    tags = {
        Name = "${var.env_prefix}-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["al2023-ami-2023.0.20230614.0-kernel-6.1-x86_64"]
    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
  
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = file(var.public_key_location)
}
resource "aws_instance" "myapp" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type

    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    availability_zone = var.avail_zone

    associate_public_ip_address = true
    key_name = aws_key_pair.ssh-key.key_name

    # user_data = file("entry-script.sh")
    connection { # to establish connection
      type = "ssh"
      host = self.public_ip
      user = "ec2-user"
      private_key = file(var.private_key_location)
    }
    # provisioner "remote-exec" {   #allow to connect remote server and exec commands
    #   inline = [
    #     "export ENV=dev",
    #     "mkdir newdir"
    #   ]
    # }
    provisioner "file" {   #to copy file from local to remote machine
      source = "entry-script.sh"
      destination = "/home/ec2-user/entry-script-on-ec2.sh"
    }
}

output "aws_instance_ip" {
    value = aws_instance.myapp.public_ip
}