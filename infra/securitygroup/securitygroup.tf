
#---------Security for App -----------------


resource "aws_security_group" "allow-traffic" {
    name            = var.public-sg-name
    description     = "Allow TLS inbound traffic and all outbound traffic"
    vpc_id          =  var.vpc_id
    tags = {
        Name    =   "allow-traffic-app"
    }  

}

#---------inbound-----------------

resource "aws_vpc_security_group_ingress_rule" "allow-443" {

    security_group_id = aws_security_group.allow-traffic.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443

}

resource "aws_vpc_security_group_ingress_rule" "allow-80" {

    security_group_id = aws_security_group.allow-traffic.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
}

resource "aws_vpc_security_group_ingress_rule" "allow-22" {

    security_group_id = aws_security_group.allow-traffic.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 22
    ip_protocol = "tcp"
    to_port = 22
}


#---------Outbound-----------------

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.allow-traffic.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#---------------------------------------------------------------------------------------------

#---------------------------------------Security for RDS ----------------------------------------

resource "aws_security_group" "allow-RDS" {
    name            = var.private-sg-name
    description     = "Allow TLS inbound RDS traffic and all inbound traffic"
    vpc_id          =  var.vpc_id
    tags = {
        Name    =   "allow-traffic-RDS"
    }  

}

resource "aws_vpc_security_group_ingress_rule" "allow-22RDS" {

    security_group_id = aws_security_group.allow-RDS.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 22
    ip_protocol = "tcp"
    to_port = 22
}


resource "aws_vpc_security_group_ingress_rule" "allow-3306RDS" {

    security_group_id = aws_security_group.allow-RDS.id
    cidr_ipv4 = "0.0.0.0/0"
    from_port = 3306 
    ip_protocol = "tcp"
    to_port = 3306 
}
