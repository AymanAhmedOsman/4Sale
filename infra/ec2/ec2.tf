resource "aws_instance" "web" {
    ami             =   var.ec2-ami
    instance_type   =    var.instance-type
    # subnet_id       =     aws_subnet.subnet_private1_demo.id
    subnet_id       =    var.subnet_id-private1
    vpc_security_group_ids = [var.public-sg-name]
    key_name = aws_key_pair.demo_key.key_name
    associate_public_ip_address = false
    user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install nginx -y
              systemctl start nginx
              systemctl enable nginx
              EOF

    tags    =   {
            Name    =   "APP"
    }  
}











