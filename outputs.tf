output "beanenv_name" {
  value = aws_elastic_beanstalk_environment.app.name
}

output "sg_servers_id" {
  value = aws_security_group.servers.id
}

output "load_balancers" {
  value = aws_elastic_beanstalk_environment.app.load_balancers
}

output "endpoint_url" {
  value = aws_elastic_beanstalk_environment.app.endpoint_url
}