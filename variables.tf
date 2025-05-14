variable "project" { type = string }
variable "systemenv" { type = string }
variable "name" { type = string }

variable "beanstalk_app" { type = string }
variable "beanstalk_stack" { type = string }

variable "beanstalk_role_policies_arns" { default = {} }

## Explicit Settings
variable "root_key_id" { type = string }
variable "securityGroupIds" { 
  type = list 
  default = []
}
variable "sshSecurityGroupIds" { 
  type = string 
  default = ""
}

variable "vpc_id" { type = string }
variable "subnetIds" { type = string }
variable "ELBSubnets" { type = string }

variable "snsNotificationEndpoint" { type = string }

variable "SSLCertificateArns" { 
  type = string 
  default = null
}
variable "sharedBalancer" { 
  type = bool
  default = false 
}
variable "SharedLoadBalancerArn" { 
  type = string
  default = "" 
}
#Defaults
variable "minSizeDefault" { 
  type = number
  default = 1 
}
variable "MaxSizeDefault" { 
  type = number
  default = 1  
}
variable "RootVolumeSizeDefault" { 
  type = number
  default = 20  
}
variable "ec2SizeDefault" { 
  type = string
  default = "t3.small"  
}
variable "enhancedMonitoringDefault" { 
  type = bool
  default = false  
}


variable "settings" { default = {} }
variable "extraSettings" { default = {} }
variable "extra_env" { default = {} }

variable "route53Records" { default = {} }
variable "route53BaseDomain" {
  type = string
  default = ""
}
variable "createRoute53Records" { 
  type = bool
  default = false  
}
variable "netAppPorts" { default = {} }
variable "netAdminAccess" { 
  type = list
  default = [] 
}
variable "netAllowOutgoing" { 
  type = bool
  default = true  
}


