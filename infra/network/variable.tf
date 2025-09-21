variable "region" {
    type = string
    default = "us-east-1"
  
}

variable "vpc-cidr_block" {
    type = string
    default = "10.0.0.0/16"
  
}
variable "subnet_public1_cidr" {
    type = string
    default = "10.0.0.0/24"
  
}
variable "subnet_public2_cidr" {
    type = string
    default = "10.0.1.0/24"
  
}
variable "subnet_private1_cidr" {
    type = string
    default = "10.0.2.0/24"
  
}
variable "subnet_private2_cidr" {
    type = string
    default = "10.0.2.0/24"
  
}


