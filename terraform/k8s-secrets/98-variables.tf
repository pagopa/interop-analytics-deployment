variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the interop EKS cluster"
}

variable "TF_VAR_namespace" {
  type        = string
  description = "Namespace where the secrets will be replicated in the EKS cluster"
  default     = "dev-analytics" # Default value, it can be overridden by the workflow input
}