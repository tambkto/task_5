resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.owner_name}_cluster"
}
resource "aws_ecr_repository" "nginx_repo" {
  name = "umar/repo"
  force_delete = true
}
resource "null_resource" "push_nginx_to_ecr" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<EOT
      set -e
      pwd
      ls -l ..
      aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${aws_ecr_repository.nginx_repo.repository_url}
      docker build -t nginx:v0 .
      docker tag nginx:v0 ${aws_ecr_repository.nginx_repo.repository_url}:latest
      docker push ${aws_ecr_repository.nginx_repo.repository_url}:latest
    EOT
  }

  depends_on = [aws_ecr_repository.nginx_repo] //ensures ecr repo is created before script runs
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#IAM role  policy for pulling image from ecr
resource "aws_iam_role_policy_attachment" "ecs_execution_ecr" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# Task role to access EFS
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}
# Attaching policy with Task Role
resource "aws_iam_role_policy" "efs_access_policy" {
  name = "efs-access"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = var.efs-arn
      }
    ]
  })
}

# Creating an ECS task definition
resource "aws_ecs_task_definition" "task" {
  family                   = "${var.owner_name}_task_definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn = aws_iam_role.ecs_task_role.arn
  volume { 
    name = "umar-efs" //use name from creation tag in efs
    efs_volume_configuration {
      file_system_id = var.efs_id
      transit_encryption = "ENABLED"
      root_directory = "/"
      authorization_config {
        iam = "DISABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name: "nginx",
      image: "${aws_ecr_repository.nginx_repo.repository_url}:latest",
      cpu: 512,
      memory: 2048,
      essential: true,
      mountPoints = [{
        sourceVolume = "umar-efs" 
        containerPath  = "/mnt/efs"
      }
      ]
      portMappings: [
        {
          containerPort: 80,
          hostPort: 80,
        },
      ],
    },
  ])
}
#creating security group
resource "aws_security_group" "ecs_sg" {
    vpc_id = var.vpcid
    tags = {
        Name = "SG-ec2${var.owner_name}"
    }
}
resource "aws_vpc_security_group_ingress_rule" "ingress" {
    security_group_id = aws_security_group.ecs_sg.id
    from_port = 80
    ip_protocol = "tcp"
    to_port = 80
    cidr_ipv4 = var.cidr_allowing_all
}
resource "aws_vpc_security_group_ingress_rule" "ingress1" {
    security_group_id = aws_security_group.ecs_sg.id
    from_port = 443
    ip_protocol = "tcp"
    to_port = 443
    cidr_ipv4 = var.cidr_allowing_all
}
resource "aws_vpc_security_group_ingress_rule" "ingress2" {
    security_group_id = aws_security_group.ecs_sg.id
    from_port = 2049
    ip_protocol = "tcp"
    to_port = 2049
    cidr_ipv4 = var.cidr_allowing_all
}
resource "aws_vpc_security_group_egress_rule" "egress" {
    security_group_id = aws_security_group.ecs_sg.id
    ip_protocol = "-1"
    cidr_ipv4 = var.cidr_allowing_all
}
# Creating an ECS service
resource "aws_ecs_service" "service" {
  name             = "${var.owner_name}_service"
  cluster          = aws_ecs_cluster.ecs_cluster.id
  task_definition  = aws_ecs_task_definition.task.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets       = var.private-subnet  
  }
  
  load_balancer { //here, we have registered target with LB
    target_group_arn = var.aws_lb_tg_arn
    container_name = "nginx"
    container_port = 80
  }
  depends_on = [ var.alb-listener-http ]

  lifecycle {
    ignore_changes = [task_definition]
  }
  }
