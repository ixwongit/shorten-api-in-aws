output "aws_alb_dns" {
  value = aws_lb.tf-webapp-alb.dns_name
}

output "aws_alb_healthcheck_url" {
  value = "http://${aws_lb.tf-webapp-alb.dns_name}/healthcheck"
}

output "terraform_db_host" {
  value = aws_instance.tf-mongodb.private_ip
}
