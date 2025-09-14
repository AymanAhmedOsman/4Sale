resource "tls_private_key" "AppKey" {
    algorithm = "RSA"
    rsa_bits = 4096
  
}


resource "aws_key_pair" "demo_key" {
  key_name   = "demo-key"
  public_key = tls_private_key.AppKey.public_key_openssh
}


# 3. Save private key to a local file (terraform-key.pem)
resource "local_file" "private_key" {
  content              = tls_private_key.AppKey.public_key_pem
  filename             = "D:/Ayman/4-Sales-Interview/terraform/infra/ec2/App-key.pem"
  file_permission      = "0600" # secure permissions for SSH key
}


