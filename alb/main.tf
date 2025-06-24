resource "aws_alb" "alb" {
  name = "umar-lb"  
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb_sg.id]
  subnets = var.public_subnet_ids
}
resource "aws_lb_target_group" "ip_tg_alb" {
  name        = "ip-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpcid
}
resource "aws_lb_listener" "listener" {
  load_balancer_arn         = aws_alb.alb.arn
  port                      = "80"
  protocol                  = "HTTP"

  default_action {
    type                    = "forward"
    target_group_arn        = aws_lb_target_group.ip_tg_alb.arn
  }
}
resource "aws_security_group" "alb_sg" {
    vpc_id = var.vpcid
    tags = {
        Name = "SG-ec2${var.owner-name}"
    }
}
resource "aws_vpc_security_group_ingress_rule" "ingress" {
    security_group_id = aws_security_group.alb_sg.id
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
    cidr_ipv4 = var.cidr_allowing_all
}
resource "aws_vpc_security_group_ingress_rule" "ingress1" {
    security_group_id = aws_security_group.alb_sg.id
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
    cidr_ipv4 = var.cidr_allowing_all
}
resource "aws_vpc_security_group_egress_rule" "egress" {
    security_group_id = aws_security_group.alb_sg.id
    ip_protocol = "-1"
    cidr_ipv4 = var.cidr_allowing_all
}