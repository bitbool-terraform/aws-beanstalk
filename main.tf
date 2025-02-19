locals {
  tags_module = { TFModule = "bitbool-aws-beanstalk" }  
}

data "aws_caller_identity" "current" {}

data "aws_elastic_beanstalk_hosted_zone" "app" {}

data "aws_region" "current" {}

resource "aws_elastic_beanstalk_environment" "app" {

  name                   = format("%s-%s-%s",var.project,var.systemenv,var.name)
  tier                   = "WebServer"
  cname_prefix           = format("%s-%s-%s",var.project,var.systemenv,var.name)

  application            = var.beanstalk_app #data.aws_elastic_beanstalk_application.apps["bid"].name
  solution_stack_name    = var.beanstalk_stack

  wait_for_ready_timeout = "600s"

  tags = merge( { "AppName" = "bid", "BeanstalkEnv" = var.systemenv }, local.tags_module )

#Envvars
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APPLICATION"
    value     = var.name
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PROJECT"
    value     = var.project
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SYSTEMENV"
    value     = var.systemenv
    resource  = ""
  }

  dynamic "setting" {
    for_each = try(var.extra_env,{})
    content {
      namespace = "aws:elasticbeanstalk:application:environment"
      name      = setting.key
      value     = setting.value
      resource  = ""
    }
  }

### Internal Settings
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.beanstalk_env.name
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_env.arn
    resource  = ""
  }

## Explicit Settings
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = var.root_key_id
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = join(",",sort(concat([aws_security_group.servers.id,aws_security_group.access.id],var.securityGroupIds)))
    resource  = ""
  }


  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SSHSourceRestriction"
    value     = format("tcp,22,22,%s",length(var.sshSecurityGroupIds)>0 ? var.sshSecurityGroupIds: aws_security_group.servers.id ) #"tcp,22,22,${aws_security_group.appservers[0].id}"
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = var.subnetIds #lookup(each.value,"natgw",false) == true ? join(",",sort(local.subnet_ids_private)) : join(",",sort(local.subnet_ids_public)) 
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = var.ELBSubnets #join(",",sort(local.subnet_ids_public)) 
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:sns:topics"
    name      = "Notification Endpoint"
    value     = var.snsNotificationEndpoint #local.sns_endpoints_beanstalk
    resource  = ""
  }


#Configurable settings
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = lookup(var.settings,"MinSize",var.minSizeDefault)
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = lookup(var.settings,"MaxSize",var.MaxSizeDefault)
    resource  = ""
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "RootVolumeSize"
    value     = lookup(var.settings,"RootVolumeSize",var.RootVolumeSizeDefault)
    resource  = ""
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = lookup(var.settings,"ec2Size",var.ec2SizeDefault)
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "HealthStreamingEnabled"
    value     = lookup(var.settings,"enhancedMonitoring",var.enhancedMonitoringDefault) 
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = lookup(var.settings,"enhancedMonitoring",var.enhancedMonitoringDefault)  ? "enhanced" : "basic"
    resource  = ""
  }

#Balancer Settings
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
    resource  = ""
  }

#OWN BALANCER ONLY
  dynamic "setting" {
    for_each = var.sharedBalancer ? [] : ["shared"] 
    content {
      namespace = "aws:elbv2:listener:443"
      name      = "Protocol"
      value     = "HTTPS"
      resource  = ""
    }
  }

  dynamic "setting" {
    for_each = var.sharedBalancer ? [] : ["shared"] 
    content {
      namespace = "aws:elbv2:listener:443"
      name      = "SSLCertificateArns"
      value     = var.SSLCertificateArns #data.aws_acm_certificate.base.arn
      resource  = ""
    }
  }


#SHARED BALANCER
  dynamic "setting" {
    for_each = var.sharedBalancer ? ["shared"] : []
    content {
      namespace = "aws:elasticbeanstalk:environment"
      name      = "LoadBalancerIsShared"
      value     = "true"
      resource  = ""
    }
  }

  dynamic "setting" {
    for_each = var.sharedBalancer ? ["shared"] : []
    content {
      namespace = "aws:elbv2:loadbalancer"
      name      = "SharedLoadBalancer"
      value     = var.SharedLoadBalancerArn #try(data.terraform_remote_state.front.outputs.lb_arns[each.value.alb],null)
      resource  = ""
    }
  }


  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Rules"
    value     = "app"
    resource  = ""
  }

  setting {
    namespace = "aws:elbv2:listenerrule:app"
    name      = "HostHeaders"
    value     = format("%s-%s-%s.%s.elasticbeanstalk.com",var.project,var.systemenv,var.name,data.aws_region.current.name)
    resource  = ""
  }

  setting {
    namespace = "aws:elbv2:listenerrule:app"
    name      = "PathPatterns"
    value     = "/"
    resource  = ""
  }

  setting {
    namespace = "aws:elbv2:listenerrule:app"
    name      = "Priority"
    value     = 980
    resource  = ""
  }  




#Static Settings

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "StickinessEnabled"
    value     = "true"
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = try(var.settings.healthCheckUrl,"/")
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = try(var.settings.healthCheckUrl,"/")
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:health"
    name      = "RetentionInDays"
    value     = 30
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = true
    resource  = ""
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = 60
    resource  = ""
  }

  # setting {
  #   namespace = "aws:elasticbeanstalk:managedactions"
  #   name      = "ServiceRoleForManagedUpdates"
  #   value     = "aws-elasticbeanstalk-service-role"
  #   resource  = ""
  # }


  # setting {
  #   namespace = "aws:elasticbeanstalk:managedactions"
  #   name      = "ManagedActionsEnabled"
  #   value     = "true"
  #   resource  = ""
  # }

  # setting {
  #   namespace = "aws:elasticbeanstalk:managedactions"
  #   name      = "PreferredStartTime"
  #   value     = "Mon:07:00"
  #   resource  = ""
  # }

  # setting {
  #   namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
  #   name      = "UpdateLevel"
  #   value     = "minor"
  #   resource  = ""
  # }

  # setting {
  #   namespace = "aws:elasticbeanstalk:managedactions"
  #   name      = "ServiceRoleForManagedUpdates"
  #   value     = #AWSServiceRoleForElasticBeanstalkManagedUpdates "aws-elasticbeanstalk-service-role"
  #   resource  = ""
  # }

  setting {
    name      = "LowerThreshold"
    namespace = "aws:autoscaling:trigger"
    resource  = ""
    value     = "30"
  }
  setting {
    name      = "MeasureName"
    namespace = "aws:autoscaling:trigger"
    resource  = ""
    value     = "CPUUtilization"
  }
  setting {
    name      = "Unit"
    namespace = "aws:autoscaling:trigger"
    resource  = ""
    value     = "Percent"
  }
  setting {
    name      = "UpperThreshold"
    namespace = "aws:autoscaling:trigger"
    resource  = ""
    value     = "80"
  }

  dynamic "setting" {
    for_each = try(var.extraSettings,{})
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
      resource  = ""
    }
  }

}
