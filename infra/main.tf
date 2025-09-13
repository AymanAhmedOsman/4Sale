module "network" {
    source = "./network"
    region  = var.region
    vpc-cidr_block= var.vpc-cidr_block
    subnet_public1_cidr= var.subnet-public1-cider
    subnet_public2_cidr= var.subnet-public2-cider
    subnet_private1_cidr= var.subnet-private1-cider
    rds-sg-name = var.rds-sg-name
    subnet_private2_cidr= var.subnet-private2-cider

}

#----------------RDS-module--------

# module "rds" {
#     source = "./rds"
#     rds-password= var.rds-password
#     rds-username=var.rds-username
#     rds-instance_class=var.rds-instance_class
#     rds-name= var.rds-name
#     rds-sg-name = module.network.rds-sg-name
#     private-sg-name = module.security_groups.private-sg-name
# }


#------------ALB-Module--------------

module "alb" {
    source = "./alb"
    vpc_id= module.network.vpc_id
    alb-name = var.alb-name
    instance-id = module.ec2.instance-id
    public-sg-name = module.security_groups.public-sg-name
    subnet_id-public1 = module.network.subnet_id-public1
    subnet_id-public2 = module.network.subnet_id-public2
    
}

#------------EC2--------------

module "ec2" {
    source = "./ec2"
    instance-type= var.instance-type
    ec2-ami= var.ec2-ami
    subnet_id-private1= module.network.subnet_id-private1
    public-sg-name = module.security_groups.public-sg-name
    subnet_id-public2 = module.network.subnet_id-public2
    ec2-ami-importTF = var.ec2-ami-importTF

}    

module "security_groups" {
    source = "./securitygroup"
    private-sg-name = var.private-sg-name
    public-sg-name = var.public-sg-name
    vpc_id = module.network.vpc_id
  
}

#----EKSModule----------
 module "eks" {
   
   source = "./eks"
cluster-name= var.cluster-name
subnet-private-1-id =module.network.subnet_id-private1
subnet-private-2-id =module.network.subnet_id-private2
subnet-public-1-id =module.network.subnet_id-public1
subnet-public-2-id =module.network.subnet_id-public2
node-group-name =var.node-group-name
 
 }