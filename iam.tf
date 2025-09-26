data "aws_iam_policy_document" "role_assumable_by_ec2" {
  statement {
    effect = "Allow"
    actions = [ "sts:AssumeRole" ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "role_assumable_by_beanstalk" {
  statement {
    effect = "Allow"
    actions = [ "sts:AssumeRole" ]
    principals {
      type        = "Service"
      identifiers = ["elasticbeanstalk.amazonaws.com"]
    }
  }
}

resource "aws_iam_instance_profile" "beanstalk_env" {
  name  = format("%s-beanstalk_env",var.name)
  role = aws_iam_role.beanstalk_env.name
}

resource "aws_iam_role" "beanstalk_env" {
  name               = format("%s-beanstalk_env",var.name)
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.role_assumable_by_ec2.json
}


resource "aws_iam_role_policy_attachment" "beanstalk_env_ssmcore" {
  role       = aws_iam_role.beanstalk_env.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# resource "aws_iam_role_policy_attachment" "beanstalk_app_access" {
#   role       = aws_iam_role.beanstalk_env.name
#   policy_arn = aws_iam_policy.application_access.arn
# }


# resource "aws_iam_policy" "application_access" {
#   name   = format("%s-beanstalk-appaccess",var.name)
#   path   = "/"
#   policy = jsonencode({
#       "Version": "2012-10-17",
#       "Statement": [
#         {
#           "Sid": "S3FullAccess",
#           "Action": [
#             "s3:Get*",
#             "s3:List*",
#             "s3:PutObject",
#             "s3:PutObjectAcl",
#             "s3:DeleteObject"
#           ],
#           "Effect": "Allow",
#           "Resource": "${sort(concat(formatlist("arn:aws:s3:::%s",local.all_buckets_ids),formatlist("arn:aws:s3:::%s/*",local.all_buckets_ids)))}"
#         }, 
#         {
#           "Sid": "S3ReadOnlyAccess",
#           "Action": [
#             "s3:Get*",
#             "s3:List*"
#           ],
#           "Effect": "Allow",
#           "Resource": "${sort(concat(formatlist("arn:aws:s3:::%s",local.all_buckets_ids),formatlist("arn:aws:s3:::%s/*",local.all_buckets_ids)))}"
#         },         
#         {
#           "Sid": "secretsaccesslist",
#           "Effect": "Allow",
#           "Action": [
#               "secretsmanager:GetRandomPassword",
#               "secretsmanager:ListSecrets"
#           ],
#           "Resource": "*"
#         },               
#         {
#           "Effect": "Allow",
#           "Action": [
#               "secretsmanager:GetResourcePolicy",
#               "secretsmanager:GetSecretValue",
#               "secretsmanager:DescribeSecret",
#               "secretsmanager:ListSecretVersionIds"
#           ],
#           "Resource": [ "${format("arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:winpl/%s/%s/%s*",var.project,var.systemenv,each.value.app_name)}"]
#         }                        
#       ]
#     })

# }

# resource "aws_iam_role_policy_attachment" "beanstalk_env_dbiamaccess" {
#   role       = aws_iam_role.beanstalk_env.name
#   policy_arn = aws_iam_policy.dbiam.arn
# }


# resource "aws_iam_policy" "dbiam" {
#   name   = format("%s-beanstalk_dbiam",var.name)
#   path   = "/"

  
#   policy= jsonencode(
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Sid": "allowConnect",
#       "Effect": "Allow",
#       "Action": "rds-db:connect",
#       "Resource": "arn:aws:rds-db:*:*:dbuser:${data.terraform_remote_state.storage.outputs.db_resource_ids[var.storage_workspace]}/${local.environment_app[var.project][var.systemenv]["mainapp"]["MYSQL_USER"]}*"
#     }
#   ]
# }
#   )

# }

resource "aws_iam_role_policy_attachment" "beanstalk_env_main" {
  role       = aws_iam_role.beanstalk_env.name
  policy_arn = aws_iam_policy.beanstalk_env.arn
}

resource "aws_iam_policy" "beanstalk_env" {
  name   = format("%s-beanstalk_systemaccess",var.name)
  path   = "/"
  policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "BucketAccess",
          "Action": [
            "s3:Get*",
            "s3:List*",
            "s3:PutObject"
          ],
          "Effect": "Allow",
          "Resource": [
            "arn:aws:s3:::elasticbeanstalk-*",
            "arn:aws:s3:::elasticbeanstalk-*/*",
          ]
        },        
        {
          "Sid": "XRayAccess",
          "Action":[
            "xray:PutTraceSegments",
            "xray:PutTelemetryRecords",
            "xray:GetSamplingRules",
            "xray:GetSamplingTargets",
            "xray:GetSamplingStatisticSummaries"
          ],
          "Effect": "Allow",
          "Resource": "*"
        },
        {
          "Sid": "CloudWatchLogsAccess",
          "Action": [
            "logs:PutLogEvents",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:DescribeLogGroups",
            "logs:CreateLogGroup"
          ],
          "Effect": "Allow",
          "Resource": [
            "arn:aws:logs:*:*:log-group:/aws/elasticbeanstalk*"
          ]
        },
        {
            "Sid": "CloudWatchMetrics",          
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"                
            ],
            "Resource": [
                "*"
            ]
        },        
        {
          "Sid": "ElasticBeanstalkHealthAccess",
          "Action": [
            "elasticbeanstalk:PutInstanceStatistics"
          ],
          "Effect": "Allow",
          "Resource": [
            "arn:aws:elasticbeanstalk:*:*:application/*",
            "arn:aws:elasticbeanstalk:*:*:environment/*"
          ]
        },
        {
          "Sid": "SNSAccess",          
          "Effect": "Allow",
          "Action": [
            "sns:SetTopicAttributes",
            "sns:GetTopicAttributes",
            "sns:Subscribe",
            "sns:Unsubscribe",
            "sns:Publish",
            "sns:CreateTopic",
            "sns:DeleteTopic"
          ],
          "Resource": [
            "*"
          ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticloadbalancing:DescribeInstanceHealth",
                "elasticloadbalancing:DescribeLoadBalancers",
                "elasticloadbalancing:DescribeTargetHealth",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:GetConsoleOutput",
                "ec2:AssociateAddress",
                "ec2:DescribeAddresses",
                "ec2:DescribeSecurityGroups",
                "sqs:GetQueueAttributes",
                "sqs:GetQueueUrl",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeScalingActivities",
                "autoscaling:DescribeNotificationConfigurations",
                "sns:Publish"
            ],
            "Resource": [
                "*"
            ]
        },
        {
            "Sid": "EcrLogin",
            "Effect": "Allow",
            "Action": [
                "ecr:DescribeRegistry",
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Sid": "EcrPull",
            "Effect": "Allow",
            "Action": [
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer"            
            ]
            "Resource": "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/*"
        }                       
      ]
    })

}

resource "aws_iam_role_policy_attachment" "beanstalk_policies" {
   for_each = var.beanstalk_role_policies_arns

  role       = aws_iam_role.beanstalk_env.name
  policy_arn = each.value
}


