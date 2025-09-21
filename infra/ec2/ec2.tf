resource "aws_instance" "JumpServer" {
    ami             =   var.ec2-ami
    instance_type   =    var.instance-type
    subnet_id       =    var.subnet_id-public2
    vpc_security_group_ids = [var.public-sg-name]
    key_name = aws_key_pair.demo_key.key_name
    associate_public_ip_address = true

    tags    =   {
            Name    =   "JumpServer"
    }  
}











