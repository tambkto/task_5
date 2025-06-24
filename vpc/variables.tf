variable "owner_name" {
  type = string
}
variable "vpc_cidr" {
  type = string
}
variable "public_subnet_cidr" {
  type = map(object({
    cidr = string
    az = string
  }))
}
variable "cidr_allowing_all" {
  type = string
}
variable "private_subnet_cidr" {
  type = map(object({
    cidr = string
    az = string
  }))
}