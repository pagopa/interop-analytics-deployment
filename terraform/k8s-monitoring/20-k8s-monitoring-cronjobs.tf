data "local_file" "cronjobs_list" {
  filename = "${path.module}/assets/cronjobs-list.json"
}

locals {
  cronjobs_names = jsondecode(data.local_file.cronjobs_list.content)
}

resource "aws_cloudwatch_metric_alarm" "cronjob_errors" {
  for_each = toset(local.cronjobs_names)

  alarm_name        = format("k8s-cronjob-%s-errors-%s", each.key, var.k8s_namespace)
  alarm_description = format("Cronjob errors alarm for %s in %s namespace", each.key, var.k8s_namespace)

  alarm_actions = [data.aws_sns_topic.analytics_alarms.arn]

  metric_name = try(data.external.cloudwatch_log_metric_filters.result.metricName, null)
  namespace   = try(data.external.cloudwatch_log_metric_filters.result.metricNamespace, null)

  dimensions = {
    PodApp       = each.key
    PodNamespace = format("%s", var.k8s_namespace)
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = 1
  period              = 60 # 1 minute
  evaluation_periods  = 5
  datapoints_to_alarm = 1

  tags = var.tags
}
