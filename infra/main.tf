# ----------------------------------------------
# 1. INFRAESTRUCTURA DE RED (VPC, Subredes, Rutas)
# ----------------------------------------------

# A. Definición de la VPC
resource "aws_vpc" "app_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "gastos-app-vpc" }
}

# B. Subredes Públicas (Para Balanceador de Cargas)
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "gastos-app-public-a" }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  tags                    = { Name = "gastos-app-public-b" }
}

# C. Subredes Privadas (Para Fargate y RDS)
resource "aws_subnet" "private_subnet_a" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "gastos-app-private-a" }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags              = { Name = "gastos-app-private-b" }
}

# D. Internet Gateway (Conexión a Internet para subredes públicas)
resource "aws_internet_gateway" "app_igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags   = { Name = "gastos-app-igw" }
}

# E. Tabla de Rutas Públicas (Dirige el tráfico de 0.0.0.0/0 al IGW)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_igw.id
  }
}

# F. Asociación de Tablas de Rutas
resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# ----------------------------------------------
# 2. GRUPOS DE SEGURIDAD (Security Groups)
# ----------------------------------------------

# G. Security Group para el Balanceador de Cargas (ALB)
resource "aws_security_group" "alb_sg" {
  vpc_id = aws_vpc.app_vpc.id
  name   = "alb-sg"

  # Entrada: HTTP/80 y HTTPS/443 desde cualquier lugar
  ingress { from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443; to_port = 443; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  # Salida libre
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# H. Security Group para el Servicio ECS/Fargate
resource "aws_security_group" "ecs_sg" {
  vpc_id = aws_vpc.app_vpc.id
  name   = "ecs-sg"

  # Entrada: Tráfico del puerto 3000 (app.js) SOLO desde el ALB
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  # Salida libre
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# I. Security Group para la Base de Datos (RDS)
resource "aws_security_group" "db_sg" {
  vpc_id = aws_vpc.app_vpc.id
  name   = "db-access-sg"

  # Entrada: Puerto 3306 (MySQL) SOLO desde el ECS Service
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
  }
  # Salida libre
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# ----------------------------------------------
# [cite_start]3. BASE DE DATOS GESTIONADA (AWS RDS) [cite: 22]
# ----------------------------------------------

# J. Grupo de Subredes DB (Requisito de RDS)
resource "aws_db_subnet_group" "gastos_db_subnet_group" {
  name       = "gastos-db-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
}

# K. Instancia de Base de Datos RDS
resource "aws_db_instance" "gastos_db" {
  identifier             = "gastos-app-db"
  engine                 = "mysql"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = "admin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.gastos_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  publicly_accessible    = false # ¡Seguro!
  skip_final_snapshot    = true
  tags                   = { Name = "GastosDB" }
}

# ----------------------------------------------
# [cite_start]4. BALANCEADOR DE CARGAS (ALB) Y CERTIFICADO SSL [cite: 23, 26]
# ----------------------------------------------

# L. Balanceador de Cargas (Application Load Balancer)
resource "aws_lb" "gastos_alb" {
  name               = "gastos-app-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

# M. Target Group (Destino: ECS Service en puerto 3000)
resource "aws_lb_target_group" "gastos_tg" {
  name     = "gastos-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.app_vpc.id

  [cite_start]health_check { # Health Check configurado [cite: 24]
    path    = "/"
    matcher = "200"
  }
}

# N. Configuración de Dominio y Certificado SSL (asumiendo Route 53)
data "aws_route53_zone" "primary" {
  name         = "midominio-gratuito.com." # << REEMPLAZAR con tu dominio
  private_zone = false
}

resource "aws_acm_certificate" "gastos_cert" {
  domain_name       = "app.midominio-gratuito.com" # << REEMPLAZAR con tu subdominio
  validation_method = "DNS"
}

# O. Listener HTTP (Puerto 80: Dirige al Target Group)
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.gastos_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gastos_tg.arn
  }
}

# [cite_start]P. Listener HTTPS (Puerto 443: Usa el certificado SSL [cite: 26])
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.gastos_alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.gastos_cert.arn # Certificado SSL

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gastos_tg.arn
  }
}

# [cite_start]Q. Registro DNS (Route 53: Asocia el dominio al Balanceador de Cargas [cite: 25])
resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "app.midominio-gratuito.com" # << REEMPLAZAR con tu subdominio
  type    = "A"

  alias {
    name                   = aws_lb.gastos_alb.dns_name
    zone_id                = aws_lb.gastos_alb.zone_id
    evaluate_target_health = true
  }
}


# ----------------------------------------------
# [cite_start]5. SERVIDOR DE APLICACIONES (ECS FARGATE) [cite: 18]
# ----------------------------------------------

# R. Roles de IAM necesarios para ECS Fargate
resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role-gastos"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole"; Effect = "Allow"; Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs-execution-role-gastos"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole"; Effect = "Allow"; Principal = { Service = "ecs-tasks.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# S. Cluster ECS
resource "aws_ecs_cluster" "gastos_cluster" {
  name = "gastos-app-cluster"
}

# [cite_start]T. Task Definition (La "receta" del contenedor con tu imagen de Docker Hub [cite: 21])
resource "aws_ecs_task_definition" "gastos_task" {
  family                   = "gastos-task-family"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "gastos-app-container"
      image     = var.app_image_url # Tu imagen de Docker Hub (ej: elibarraza/gastos-app:1.0)
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      # Configurar variables de entorno aquí para conectar a RDS
      environment = [
        { name = "DB_HOST", value = aws_db_instance.gastos_db.address },
        { name = "DB_USER", value = aws_db_instance.gastos_db.username },
        { name = "DB_PASSWORD", value = var.db_password },
        { name = "DB_NAME", value = aws_db_instance.gastos_db.name }
      ]
    }
  ])
}

# U. ECS Service (Despliegue y conexión al Load Balancer)
resource "aws_ecs_service" "gastos_service" {
  name            = "gastos-app-service"
  cluster         = aws_ecs_cluster.gastos_cluster.id
  task_definition = aws_ecs_task_definition.gastos_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    # El servicio Fargate debe ir en las subredes privadas por seguridad
    subnets         = [aws_subnet.private_subnet_a.id, aws_subnet.private_subnet_b.id]
    security_groups = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.gastos_tg.arn
    container_name   = "gastos-app-container"
    container_port   = 3000
  }
}