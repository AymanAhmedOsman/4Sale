#-------------------------Application Load Balancer--------------------

resource "aws_lb" "alb-app" {
    name = var.alb-name
    internal = false
    load_balancer_type = "application"
    security_groups = [var.public-sg-name]
    subnets = [var.subnet_id-public1, var.subnet_id-public2]

    tags = {
        Name    =   "alb-demo"
    }
  
}
#---------------listner-------
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.alb-app.arn
    port = 80
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_alb_target_group.tg-app.arn
    }

  
}


#----------------Target Group-------------
resource "aws_alb_target_group" "tg-app" {
  name = "lb-tg-app"
  port = 80
  protocol = "HTTP"
  #vpc_id = aws_vpc.vpc-demo.id
  vpc_id = var.vpc_id

  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
  
}


#-----------------TG Attachments-----------------


resource "aws_lb_target_group_attachment" "demo-attachment" {
  target_group_arn = aws_alb_target_group.tg-app.arn
  target_id = var.instance-id
  port = 80
  
}