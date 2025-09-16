variable "region" {
    type = string
  
}
variable "vpc-cidr_block" {
    type = string
  
}


variable "subnet-public1-cider" {
    type = string
}
variable "subnet-public2-cider" {
    type = string
  
}
variable "subnet-private1-cider" {
    type = string
  
}
variable "subnet-private2-cider" {
    type = string
  
}
#--------------EC2-------------

variable "ec2-ami" {
    type = string
  
}

variable "instance-type" {
    type = string
  
}


#--------security-group-------------

variable "public-sg-name" {
  type = string
}
variable "private-sg-name" {
  type = string
}


#------------EKS--------------
variable "cluster-name" {
    type = string
    default = "demo-cluster"
  
}


variable "node-group-name" {
    type = string
    default = ""
  
}



    
   
    
   