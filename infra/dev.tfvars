#------------------Network-------------
region                  = "eu-west-1"
vpc-cidr_block          = "10.0.0.0/16"
subnet-public1-cider    = "10.0.0.0/24"
subnet-public2-cider    = "10.0.3.0/24"
subnet-private1-cider   = "10.0.1.0/24"
subnet-private2-cider   = "10.0.2.0/24"
rds-sg-name             = "rds-subnet group"

#---------------EC2-----------
instance-type = "t3.micro"
ec2-ami = "ami-01f23391a59163da9"
ec2-ami-importTF = "ami-09b024e886d7bbe74"
#-----------------ELB-----------

alb-name= "demo-alb"
#--------------RDS-----------
# rds-instance_class      = "db.t3.micro"
# rds-username            = "foo"
# rds-password            = "foobarbaz"
# alb-name                = "demo-alb"
# rds-name                = "demords"

#--------------------Security-group--------------

public-sg-name      = "Allow-HTTP"
private-sg-name     = "Allow-RDs-Access "

#----------EKS------------

cluster-name= "demo-cluster"
node-group-name= "demo-node-group"
 
