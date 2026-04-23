/**
 * An ECR repository for storing the Lambda function code. Operates
 * as a pull through of a Docker image from GHCR.
 */

data "aws_caller_identity" "current" {}

locals {
  account_id    = data.aws_caller_identity.current.account_id
  ecr_registry  = "${local.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  ecr_repo_url  = "${local.ecr_registry}/${var.name}"
  image_tag     = var.ghcr_tag
  ecr_image_uri = "${local.ecr_repo_url}:${local.image_tag}"
}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  // this is just a cache of our published GHCR so it can be
  // cleared aggressively
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 2 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 2
      }
      action = { type = "expire" }
    }]
  })
}

resource "null_resource" "ecr_image" {
  # Trigger is the full image URI (repo + tag). Changing the tag causes a
  # re-push; an identical URI across machines produces no diff regardless of
  # local Docker daemon state.
  triggers = {
    ecr_image_uri = local.ecr_image_uri
  }

  provisioner "local-exec" {
    command = <<-SHELL
      set -euo pipefail
      # ECR tags are IMMUTABLE — skip the push if this tag already exists.
      if aws ecr describe-images \
          --region '${var.aws_region}' \
          --repository-name '${var.name}' \
          --image-ids imageTag='${local.image_tag}' \
          --output text 2>/dev/null; then
        echo "Image ${local.ecr_image_uri} already exists in ECR, skipping push."
        exit 0
      fi
      aws ecr get-login-password --region '${var.aws_region}' | \
        docker login --username AWS --password-stdin '${local.ecr_registry}'
      docker pull --platform linux/arm64 '${var.ghcr_repo}:${var.ghcr_tag}'
      docker tag '${var.ghcr_repo}:${var.ghcr_tag}' '${local.ecr_image_uri}'
      docker push '${local.ecr_image_uri}'
    SHELL
  }

  depends_on = [aws_ecr_repository.this]
}
