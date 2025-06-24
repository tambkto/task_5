module "vpc" {
  source = "./vpc"
  vpc_cidr = var.vpc-cidr
  cidr_allowing_all = var.cidr-allowing-all
  public_subnet_cidr = var.public-subnet-cidr
  private_subnet_cidr = var.private-subnet-cidr
  owner_name = "Umar"
  providers = {
    aws = aws.ohio
  }
}
module "ecs" {
  source = "./ecs"
  owner_name = var.ownername
  private-subnet = module.vpc.private_subnet
  public-subnet = module.vpc.public_subnet
  vpcid = module.vpc.vpc_id
  cidr_allowing_all = var.cidr-allowing-all
  aws_lb_tg_arn = module.alb.aws_lb_target_group
  alb-listener-http = module.alb.alb_listener_http
  efs_id = module.efs.aws_efs_file_system_id
  efs-arn = module.efs.aws_efs_file_system_arn
  providers = {
    aws = aws.ohio
  }
}
module "alb" {
  source = "./alb"
  owner-name = var.ownername
  vpcid = module.vpc.vpc_id
  cidr_allowing_all = var.cidr-allowing-all
  public_subnet = module.vpc.public_subnet
  public_subnet_ids = module.vpc.public_subnet_ids_unique_az

  providers = {
    aws = aws.ohio
  }
}
module "efs" {
  source = "./efs"
  owner-name = var.ownername
  cidr_allowing_all = var.cidr-allowing-all
  vpcid = module.vpc.vpc_id
  private-subnet = module.vpc.private_subnet

}