# provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}


# SSH key

resource "tls_private_key" "tf-webapp-prikey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf-webapp-key" {
  key_name   = "tf-webapp-key"
  public_key = tls_private_key.tf-webapp-prikey.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.tf-webapp-prikey.private_key_pem}' > ./tf-webapp-key.pem"
  }
}

# Security Group for ALB
resource "aws_security_group" "tf-alb-sg" {
  name        = "tf-alb-sg"
  description = "tf-alb-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.tf-webapp-sg.id]
  }

  tags = {
    Name = "tf-alb-sg"
  }
}

# Security for Webapp
resource "aws_security_group" "tf-webapp-sg" {
  name        = "tf-webapp-sg"
  description = "tf-webapp-sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "tf-webapp-sg"
  }
}

resource "aws_security_group_rule" "tf-webapp-allow-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.tf-webapp-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "tf-webapp-allow-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.tf-webapp-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "tf-webapp-allow-alb" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tf-webapp-sg.id
  source_security_group_id = aws_security_group.tf-alb-sg.id
}

# ALB Setup
resource "aws_lb" "tf-webapp-alb" {
  name               = "tf-webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf-alb-sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "tf-webapp-alb"
  }
}

resource "aws_lb_target_group" "tf-webapp-alb-target-grp" {
  name     = "tf-alb-target-grp"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path = "/healthcheck"
    port = 5000
  }
}

resource "aws_lb_listener" "tf-webapp-alb-listener" {
  load_balancer_arn = aws_lb.tf-webapp-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-webapp-alb-target-grp.arn
  }
}

# Creating Webapp autoscaling group 
resource "aws_launch_configuration" "tf-webapp-launch-config" {
  name_prefix   = "tf-webapp-launch-config-"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  user_data       = data.template_file.tf_webapp_userdata.rendered
  key_name        = aws_key_pair.tf-webapp-key.key_name
  security_groups = [aws_security_group.tf-webapp-sg.id]

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_instance.tf-mongodb,
  ]
}

resource "aws_autoscaling_group" "tf-webapp-autoscaling-grp" {
  name                 = "tf-webapp-autoscaling-grp"
  min_size             = 2
  max_size             = 5
  launch_configuration = aws_launch_configuration.tf-webapp-launch-config.name
  vpc_zone_identifier  = module.vpc.public_subnets
  target_group_arns    = [aws_lb_target_group.tf-webapp-alb-target-grp.arn]
}

resource "aws_autoscaling_attachment" "tf-webapp-autoscaling-grp" {
  autoscaling_group_name = aws_autoscaling_group.tf-webapp-autoscaling-grp.id
  alb_target_group_arn   = aws_lb_target_group.tf-webapp-alb-target-grp.arn
}

# Set up the autoscaling policy to scale on 1000 request
resource "aws_autoscaling_policy" "tf-webapp-autoscaling-policy" {
  name                      = "tf-webapp-autoscaling-policy"
  autoscaling_group_name    = aws_autoscaling_group.tf-webapp-autoscaling-grp.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 60
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.tf-webapp-alb.arn_suffix}/${aws_lb_target_group.tf-webapp-alb-target-grp.arn_suffix}"
    }
    target_value = 1000.0
  }
}



# SSH key
resource "tls_private_key" "tf-db-prikey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf-db-key" {
  key_name   = "tf-db-key"
  public_key = tls_private_key.tf-db-prikey.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.tf-db-prikey.private_key_pem}' > ./tf-db-key.pem"
  }
}

# Security for Mongodb
resource "aws_security_group" "tf-db-sg" {
  name        = "tf-db-sg"
  description = "tf-db-sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "tf-db-sg"
  }
}

resource "aws_security_group_rule" "tf-db-allow-db" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tf-db-sg.id
  source_security_group_id = aws_security_group.tf-webapp-sg.id
}

resource "aws_security_group_rule" "tf-db-allow-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tf-db-sg.id
  source_security_group_id = aws_security_group.tf-webapp-sg.id
}

resource "aws_security_group_rule" "tf-db-allow-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.tf-db-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Creating Mongodb instance
resource "aws_instance" "tf-mongodb" {
  ami                    = var.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.tf-db-sg.id]
  user_data              = data.template_file.tf_db_userdata.rendered
  subnet_id              = element(module.vpc.private_subnets, 0)
  key_name               = aws_key_pair.tf-db-key.key_name

  tags = {
    Name = "tf-mongodb"
  }

  depends_on = [
    module.vpc,aws_vpc_endpoint.tf-s3-endpoint,
  ]
}


