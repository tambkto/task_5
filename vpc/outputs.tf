output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "public_subnet" {
  value = [for k in aws_subnet.public_subnet : k.id]
}
output "private_subnet" {
  value = [for k in aws_subnet.private_subnet : k.id]
}
output "public_subnet_ids_unique_az" {
  value = [
    for az, subnet in {
      for k, s in aws_subnet.public_subnet : s.availability_zone => s
    } : subnet.id
  ]
}
