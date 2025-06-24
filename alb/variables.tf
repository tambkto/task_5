variable "owner-name" {
  type = string
}
variable "vpcid" {
  type = string
}
variable "cidr_allowing_all" {
  type = string
}
variable "public_subnet" {
  type = list(string)

}
variable "public_subnet_ids" {
  type = list(string)
}