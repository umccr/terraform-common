data "aws_caller_identity" "current" {}

locals {
  admin_principal_arns = coalesce(var.admin_principal_arns, [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_AWSAdministratorAccess_*",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/*/AWSReservedSSO_PlatformOwnerAccess_*",
  ])
}
