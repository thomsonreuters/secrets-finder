resource "aws_sns_topic" "important_notifications" {
  count = var.sns_topic_receiver != null ? 1 : 0
  name  = var.project_name
}

resource "aws_sns_topic_subscription" "email_subscription" {
  count     = var.sns_topic_receiver != null ? 1 : 0
  topic_arn = aws_sns_topic.important_notifications[0].arn
  protocol  = "email"
  endpoint  = var.sns_topic_receiver
}
