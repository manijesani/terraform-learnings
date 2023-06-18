provider "aws" {}
variable "cidr_blocks" {
    description = "Subnet cidr blocks for vpc and subnet"
    type = list(object({
        cidr_block = string
        name = string
    }))
  
}
variable "avail_zone" {}
resource "aws_vpc" "development-vpc" {
    cidr_block = var.cidr_blocks[0].cidr_block
    tags = {
      Name = var.cidr_blocks[0].name
    }
  
}
resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id
    availability_zone = var.avail_zone
    cidr_block = var.cidr_blocks[1].cidr_block
    tags = {
        Name = var.cidr_blocks[1].name
    }
}
