variable "owner_name" {
  type = string
}
variable "public-subnet" {
  type = list(string)
}
variable "private-subnet" {
  type = list(string)
}
variable "vpcid" { 
  type = string
}
variable "cidr_allowing_all" {
  type = string
}
variable "aws_lb_tg_arn" {
  type = string
}
variable "alb-listener-http" {
  type = any //becasue, it's not string rather complex object the listener
}
variable "efs_id" {
  type = string
}
variable "efs-arn" {
  type = string
}