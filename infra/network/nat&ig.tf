#-------------eip for nat gateway------
resource "aws_eip" "nat_ip" {
    tags    =   {
        Name = "nat_ip"
    }
    depends_on = [aws_internet_gateway.demo-gw]
}
#-------------nat gateway--------------
resource "aws_nat_gateway" "demo-nat" {
    allocation_id = aws_eip.nat_ip.id
    subnet_id     = aws_subnet.subnet_public1_demo.id

    tags = {
        Name = "NAT-Demo"
    }

    depends_on = [aws_internet_gateway.demo-gw]

}

#-------------ig gateway---------------
resource "aws_internet_gateway" "demo-gw" {
    vpc_id  =   aws_vpc.vpc-demo.id
    
    tags    =   {
        Name = "demo-gw"
    }

}