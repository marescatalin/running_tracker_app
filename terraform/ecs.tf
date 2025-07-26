data "aws_ecr_repository" "runner_tracker_repo" {
  name       = "runner-tracker-app"
  depends_on = [aws_ecr_repository.runner_tracker_repo]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "ecs_service_discovery" {
  name        = "ecs-service-discovery"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = 7000
    to_port     = 7000
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "default_sg" {
  vpc_id = data.aws_vpc.default.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["90.207.26.44/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  

  tags = {
    Name = "default-sg"
  }
}

resource "aws_ecs_service" "springboot_service" {
  name            = "springboot-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.springboot_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  service_registries {
    registry_arn = aws_service_discovery_service.spring_api.arn
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.default_sg.id, aws_security_group.ecs_service_discovery.id]
    assign_public_ip = true
  }
  tags = {
    Name = "springboot-service"
  }
}

resource "aws_ecs_service" "node_service" {
  name            = "node-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.node_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  service_registries {
    registry_arn = aws_service_discovery_service.node_api.arn
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.default_sg.id,aws_security_group.ecs_service_discovery.id]
    assign_public_ip = true
  }
  tags = {
    Name = "node-service"
  }
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "runner-tracker-app-cluster"
}

resource "aws_ecs_task_definition" "springboot_task" {
  family                   = "springboot-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "springboot-app"
      image     = "${aws_ecr_repository.runner_tracker_repo.repository_url}:backend"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.springboot_log_group.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "node_task" {
  family                   = "node-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  task_role_arn            = aws_iam_role.ecs_task.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  container_definitions = jsonencode([
    {
      name      = "node-app"
      image     = "${aws_ecr_repository.runner_tracker_repo.repository_url}:frontend"
      essential = true
      portMappings = [
        {
          containerPort = 7000
          hostPort      = 7000
        }
      ],
      environment = [
      {
        name  = "PROXY_URL"
        value = "spring-api.example.local:8080"
      }
    ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.springboot_log_group.name
          awslogs-region        = "eu-west-2"
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])
}

resource "aws_ecr_repository" "runner_tracker_repo" {
  name                 = "runner-tracker-app"
  force_delete         = true
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "runner-tracker-repo"
  }
}

resource "aws_cloudwatch_log_group" "springboot_log_group" {
  name              = "/aws/ecs/springboot-app"
  retention_in_days = 7
}
