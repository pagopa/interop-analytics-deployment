aws_region = "eu-south-1"
env        = "prod"

tags = {
  CreatedBy   = "Terraform"
  Environment = "PROD"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-analytics-deployment"
}

eks_cluster_name = "interop-eks-cluster-prod"

sns_topic_name = "interop-platform-alarms-prod"

cloudwatch_log_group_name = "/aws/eks/interop-eks-cluster-prod/application"
