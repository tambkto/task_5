resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.owner_name}_vpc"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.owner_name}_igw"
  }
}
resource "aws_eip" "eip" {
  domain = "vpc"
  tags = {
    Name = "${var.owner_name}_eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id = aws_subnet.public_subnet["public_1a"].id //we are mentioning key value from terraform.tfvars file 
  depends_on = [ aws_internet_gateway.igw ]
  tags = {
    Name = "${var.owner_name}_nat"
  }
}
resource "aws_subnet" "public_subnet" { //now, aws_subnet.public_subnet is map 
  for_each = var.public_subnet_cidr //
  vpc_id = aws_vpc.vpc.id
  cidr_block = each.value.cidr
  availability_zone  = each.value.az
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.owner_name}_vpc_${each.key}"
  }

}
resource "aws_route_table" "public_route_table" {
  for_each = var.public_subnet_cidr //if we want to create routetable for each subnet then use for_each to loop. otherwise, don't use
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.cidr_allowing_all
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "${var.owner_name}_routetable_${each.key}"
  }
}
resource "aws_route_table_association" "public_route_table_assosciations" {
  for_each = aws_subnet.public_subnet //not cidr here rather make make public subnets created a map. Bcs, here we don't want to loop over public cidr range rather over public subnets 
  route_table_id = aws_route_table.public_route_table[each.key].id //add each.key so it can be assosciated with each route table
  subnet_id = each.value.id
}
resource "aws_subnet" "private_subnet" {
  for_each = var.private_subnet_cidr
  vpc_id = aws_vpc.vpc.id
  cidr_block = each.value.cidr
  availability_zone  = each.value.az
  tags = {
    Name = "${var.owner_name}_vpc_${each.key}"
  }
}
resource "aws_route_table" "private_route_table" {
 for_each = var.private_subnet_cidr //we are adding here because we get error while declaring name and we need to create route table for each subnet cidr
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
  Name = "${var.owner_name}_routetable_${each.key}" 
  }
}
resource "aws_route_table_association" "private_route_table_assosciation" {
  for_each = aws_subnet.private_subnet
  route_table_id = aws_route_table.private_route_table[each.key].id
  subnet_id = each.value.id
}
































# resource "aws_subnet" "public_subnet" {
#   count = length(var.public_subnet_cidr)
#   vpc_id = aws_vpc.vpc.id
#   cidr_block = element(var.public_subnet_cidr, count.index)
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "${var.owner_name}_vpc__public_subnet${count.index + 1}"
#   }
# }
# resource "aws_subnet" "private_subnet" {
#   count = length(var.private_subnet_cidr)
#   vpc_id = aws_vpc.vpc.id
#   cidr_block = element(var.private_subnet_cidr, count.index)
#   map_public_ip_on_launch = true
#   tags = {
#     Name = "${var.owner_name}_vpc__public_subnet${count.index + 1}"
#   }
# }

# resource "aws_route_table" "public_route_table" {
#   vpc_id = aws_vpc.vpc.id
#   route  {
#     cidr_block = var.cidr_allowing_all
#     gateway_id = aws_internet_gateway.igw.id
    
#   }
#   tags = {
#     Name = "${var.owner_name}_vpc_public_routetable_1"
#   }
# }
# resource "aws_route_table_association" "public_route_table_assosciations" {
#   count = length(var.public_subnet_cidr)
#   subnet_id = element(aws_subnet.public_subnet[*].id, count.index)  
#   route_table_id = aws_route_table.public_route_table.id
# }

# resource "aws_route_table" "private_route_table" {
#   vpc_id = aws_vpc.vpc.id
#   tags = {
#     Name = "${var.owner_name}_vpc_private_routetable_2"
#   }
# }
# resource "aws_route_table_association" "private_route_table_assosciation" {
#   count = length(var.private_subnet_cidr)
#   subnet_id = element(aws_subnet.private_subnet[*].id, count.index)
#   route_table_id = aws_route_table.private_route_table.id
# }
