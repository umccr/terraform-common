output "seqera_iam_user_secret_arn" {
  value       = aws_secretsmanager_secret.seqera_iam_user.arn
  description = "The ARN of the Secrets Manager secret holding IAM credentials for the Seqera user"
}

output "seqera_iam_user_name" {
  value       = aws_iam_user.batch_forge_user.name
  description = "The name of the IAM user created for Seqera"
}

output "seqera_iam_policy_arn" {
  value       = aws_iam_policy.batch_forge_policy.arn
  description = "The ARN of the IAM policy attached to the Seqera batch forge group"
}