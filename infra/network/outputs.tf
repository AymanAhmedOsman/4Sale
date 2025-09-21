output "vpc_id" {
    value = aws_vpc.vpc-demo.id 
}

output "subnet_id-public1" {
    value = aws_subnet.subnet_public1_demo.id
  
}
output "subnet_id-public2" {
    value = aws_subnet.subnet_public2_demo.id
  
}
output "subnet_id-private1" {
    value = aws_subnet.subnet_private1_demo.id
  
}
output "subnet_id-private2" {
    value = aws_subnet.subnet_private2_demo.id
  
}


