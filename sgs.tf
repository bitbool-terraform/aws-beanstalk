
resource "aws_security_group" "servers" {
  name        = format("%s-%s-%s-appservers",var.project,var.systemenv,var.name)
  description = "App Servers"
  vpc_id      = var.vpc_id

  tags = merge( {Name = format("%s-%s-%s-beanservers",var.project,var.systemenv,var.name) }, local.tags_module )
}

resource "aws_security_group" "access" {
  name        = format("%s-%s-%s-appaccess",var.project,var.systemenv,var.name)
  description = "Allow traffic to application"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.netAppPorts
    content {
      from_port       = ingress.value["port"]
      to_port         = ingress.value["port"]
      protocol        = lookup(ingress.value["proto"],"tcp")
      cidr_blocks     = lookup(ingress.value["source"],"0.0.0.0/0")
    }
  }

  dynamic "ingress" {
    for_each = length(var.netAdminAccess)>0 ? ["admins"] : []
    content {
      from_port       = 0
      to_port         = 0
      protocol        = -1
      cidr_blocks     = var.netAdminAccess
    }
  }  

  dynamic "egress" {
    for_each = var.netAllowOutgoing ? ["allowall"] : []
    content {
      from_port       = 0
      to_port         = 0
      protocol        = -1
      cidr_blocks     = ["0.0.0.0/0"]
    }
  }  

  tags = merge( {Name = format("%s-%s-%s-appaccess",var.project,var.systemenv,var.name) }, local.tags_module )
}

