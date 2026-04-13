/**
 * We create a secret that stores the IAM creds for the
 * designated Seqera user. Subsequent terraform stacks can use
 * the information from the secret to create workspace credentials.
 *
 * Note that we restrict the use of the secret to those user roles that
 * will be doing account level terraform work - through an explicit
 * Deny.
 */

# generate an access key for the IAM user - which will be available to create Seqera
# credentials
resource "aws_iam_access_key" "seqera_iam_user" {
  user = aws_iam_user.batch_forge_user.name
}

resource "aws_secretsmanager_secret" "seqera_iam_user" {
  name        = "${var.name_prefix}-iam-user"
  description = "IAM access key, secret  to be used by terraform (admin users only)"
}

resource "aws_secretsmanager_secret_version" "seqera_iam_user" {
  secret_id = aws_secretsmanager_secret.seqera_iam_user.id
  secret_string_wo = jsonencode({
    accessKeyId     = aws_iam_access_key.seqera_iam_user.id,
    secretAccessKey = aws_iam_access_key.seqera_iam_user.secret
  })
  secret_string_wo_version = "1"
}

data "aws_iam_policy_document" "seqera_iam_user" {
  statement {
    sid    = "OnlyAdminsCanInteractWithThis"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    // we want others to be able to see the secret metadata and potentially delete the secret
    // in case something is stuffed up - just not see the API token value itself.
    // so we are assuming a threat model where people are not super evil, we just don't
    // want to allow researchers to get the API token
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:*ResourcePolicy"
    ]
    resources = [aws_secretsmanager_secret.seqera_iam_user.arn]

    condition {
      variable = "aws:PrincipalArn"
      test     = "StringNotLike"
      values   = local.admin_principal_arns
    }
  }
}

resource "aws_secretsmanager_secret_policy" "seqera_iam_user" {
  secret_arn = aws_secretsmanager_secret.seqera_iam_user.arn
  policy     = data.aws_iam_policy_document.seqera_iam_user.json
}
