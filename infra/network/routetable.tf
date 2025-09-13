#------------public route table --------------

resource "aws_route_table" "route-public" {
    vpc_id  =   aws_vpc.vpc-demo.id

    route   {
        cidr_block  =   "0.0.0.0/0"
        gateway_id  =   aws_internet_gateway.demo-gw.id
    }

    tags    =   {
        Name    =   "public_rt"
    }

}

#------------public route table association --------------

resource "aws_route_table_association" "public1" {

    subnet_id           =   aws_subnet.subnet_public1_demo.id
    route_table_id      =   aws_route_table.route-public.id
}

resource "aws_route_table_association" "public2" {

    subnet_id           =   aws_subnet.subnet_public2_demo.id
    route_table_id      =   aws_route_table.route-public.id
}

#------------private route table-----------

resource "aws_route_table" "route-private" {
    vpc_id  =   aws_vpc.vpc-demo.id

    route   {
        cidr_block  =   "0.0.0.0/0"
        gateway_id  =   aws_nat_gateway.demo-nat.id
    }

    tags    =   {
        Name    =   "private_rt"
    }

}

#------------public route table association--------------

resource "aws_route_table_association" "private1" {
    subnet_id                         =   aws_subnet.subnet_private1_demo.id
    route_table_id      =   aws_route_table.route-private.id
}

resource "aws_route_table_association" "private2" {
    subnet_id            =   aws_subnet.subnet_private2_demo.id
    route_table_id       =   aws_route_table.route-private.id
}