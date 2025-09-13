#--------create VPC---------
resource "aws_vpc" "vpc-demo" {
    cidr_block = var.vpc-cidr_block
    enable_dns_hostnames = true

    tags = {
        Name = "vpc-demo"
    }
}

#--------- Public Subnet-----

resource "aws_subnet" "subnet_public1_demo" {
    vpc_id              =   aws_vpc.vpc-demo.id
    availability_zone   =   "${var.region}a"
    cidr_block          =   var.subnet_public1_cidr
    map_public_ip_on_launch = true
    tags    =   {
        Name =  "public1-demo"
    }    
}
#--------- Public Subnet-----

resource "aws_subnet" "subnet_public2_demo" {
    vpc_id              =   aws_vpc.vpc-demo.id
    availability_zone   =   "${var.region}b"
    cidr_block          =   var.subnet_public2_cidr
    map_public_ip_on_launch = true
    tags    =   {
        Name =  "public2-demo"
    }    
}

#--------- private Subnet-----

resource "aws_subnet" "subnet_private1_demo" {
    vpc_id              =   aws_vpc.vpc-demo.id
    availability_zone   =   "${var.region}a"
    cidr_block          =   var.subnet_private1_cidr
    tags    =   {
        
        Name =  "privateApp-demo"
    }    
}

#--------- private Subnet-----

resource "aws_subnet" "subnet_private2_demo" {
    vpc_id              =   aws_vpc.vpc-demo.id
    availability_zone   =   "${var.region}b"
    cidr_block          =   var.subnet_private2_cidr
    tags    =   {

        Name =  "privateDB-demo"
    }    
}



#------------subnet group--------------
resource "aws_db_subnet_group" "RDS" {
  name = var.rds-sg-name
  subnet_ids = [aws_subnet.subnet_private1_demo.id, aws_subnet.subnet_private2_demo.id]

  tags = {
    Name  = "My-RDS-SG"
  }
  
}

