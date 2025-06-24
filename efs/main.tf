resource "aws_efs_file_system" "efs" {
  creation_token = "umar-efs"
  throughput_mode = "provisioned"
  provisioned_throughput_in_mibps = 1
  tags = {
    Name = "${var.owner-name}_efs" 
  }
}
resource "aws_efs_mount_target" "efs_mount_target" { //always pass list, it doesn't expect object
    count = length(var.private-subnet)
  file_system_id = aws_efs_file_system.efs.id
  subnet_id = var.private-subnet[count.index]
  security_groups = [aws_security_group.efs_sg.id]

}
resource "aws_security_group" "efs_sg" {
    vpc_id = var.vpcid
    tags = {
        Name = "SG-ec2${var.owner-name}"
    }
}
resource "aws_vpc_security_group_ingress_rule" "ingress" {
    security_group_id = aws_security_group.efs_sg.id
    from_port = 2049
    ip_protocol = "tcp"
    to_port = 2049
    cidr_ipv4 = var.cidr_allowing_all
}

resource "aws_vpc_security_group_egress_rule" "egress" {
    security_group_id = aws_security_group.efs_sg.id
    ip_protocol = "-1"
    cidr_ipv4 = var.cidr_allowing_all
}