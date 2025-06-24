variable "vpc-cidr" {
  type = string
}
variable "cidr-allowing-all" {
  type = string
}
variable "public-subnet-cidr" {
  type = map(object({
    cidr = string
    az = string
  }))
}
variable "private-subnet-cidr" {
  type = map(object({
    cidr = string
    az = string
  }))
}
variable "ownername" {
  type = string
}