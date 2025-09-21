output "public-sg-name" {
    value = aws_security_group.allow-traffic.id
  
}

output "private-sg-name" {
    value = aws_security_group.allow-RDS.id
  
}