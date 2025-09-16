output "key_name" {
  description = "The name of the SSH key pair for EKS nodes"
  value       = aws_key_pair.demo_key.key_name
  }
