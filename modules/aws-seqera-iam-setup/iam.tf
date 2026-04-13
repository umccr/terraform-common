/*
 * The seqera IAM user is created once and is the bridge between seqera and
 * AWS.
 */

# an IAM user which will be used by Seqera to then create Batch environments
resource "aws_iam_user" "batch_forge_user" {
  name = "${var.name_prefix}-batch-forge-user"
}

# an IAM group we will put the user in - this is recommended AWS technique (see IAM.2 security control)
resource "aws_iam_group" "batch_forge_group" {
  name = "${var.name_prefix}-batch-forge-group"
}

resource "aws_iam_user_group_membership" "batch_forge_user_in_group" {
  user = aws_iam_user.batch_forge_user.name

  groups = [
    aws_iam_group.batch_forge_group.name
  ]
}

resource "aws_iam_group_policy_attachment" "attach_policies_to_group" {
  group      = aws_iam_group.batch_forge_group.name
  policy_arn = aws_iam_policy.batch_forge_policy.arn
}

# standard policies as recommended by Seqera documentation
# https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch

resource "aws_iam_policy" "batch_forge_policy" {
  # NOTE: these can't be inline policies as they are > 2048 characters
  name_prefix = "${var.name_prefix}-iam-policy-"
  description = "Policy giving permissions to Seqera for compute environments and UI"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
      {
        Sid    = "BatchEnvironmentManagementCanBeRestricted"
        Effect = "Allow"
        Action = [
          "batch:CreateComputeEnvironment",
          "batch:CreateJobQueue",
          "batch:DeleteComputeEnvironment",
          "batch:DeleteJobQueue",
          "batch:UpdateComputeEnvironment",
          "batch:UpdateJobQueue",
        ]
        Resource = [
          "arn:aws:batch:*:*:compute-environment/${var.tower_forge_prefix}*",
          "arn:aws:batch:*:*:job-queue/${var.tower_forge_prefix}*",
        ]
      },
      {
        Sid    = "BatchEnvironmentListing"
        Effect = "Allow"
        Action = [
          "batch:DescribeComputeEnvironments",
          "batch:DescribeJobDefinitions",
          "batch:DescribeJobQueues",
          "batch:DescribeJobs",
        ]
        Resource = "*"
      },
      {
        Sid    = "BatchJobsManagementCanBeRestricted"
        Effect = "Allow"
        Action = [
          "batch:CancelJob",
          "batch:RegisterJobDefinition",
          "batch:SubmitJob",
          "batch:TagResource",
          "batch:TerminateJob",
        ]
        Resource = [
          "arn:aws:batch:*:*:job-definition/*",
          "arn:aws:batch:*:*:job-queue/${var.tower_forge_prefix}*",
          "arn:aws:batch:*:*:job/*",
        ]
      },
      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#launch-template-management
      # Seqera requires the ability to create and manage EC2 launch templates using
      # optimized AMIs identified via AWS Systems Manager (SSM).
      {
        Sid    = "LaunchTemplateManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
        ]
        Resource = "*"
      },
      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#pass-role-to-batch
      # The iam:PassRole permission allows Seqera to pass execution IAM roles to AWS Batch to
      # run Nextflow pipelines.
      #
      # Permissions can be restricted to only allow passing the manually created roles
      # or the roles created by Seqera automatically with the default prefix
      # TowerForge- to the AWS Batch and EC2 services, in a specific account:
      {
        Sid      = "PassRolesToBatchCanBeRestricted"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = [
              "batch.amazonaws.com",
              "ec2.amazonaws.com",
            ]
          }
        }
      },
      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#cloudwatch-logs-access
      # Seqera requires access to CloudWatch logs to display relevant log data in the web interface.
      #
      # The policy can be scoped down to limit access to the specific log group defined on the
      # compute environment in a specific account and region:
      {
        Sid    = "CloudWatchLogsAccessCanBeRestricted"
        Effect = "Allow"
        Action = [
          "logs:Describe*",
          "logs:FilterLogEvents",
          "logs:Get*",
          "logs:List*",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:TestMetricFilter",
        ]
        Resource = "*"
      },

      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#s3-access-optional
      # Seqera automatically attempts to fetch a list of S3 buckets available in the AWS
      # account connected to Platform, to provide them in a drop-down menu to be used as
      # Nextflow working directory, and make the compute environment creation smoother.
      # This feature is optional, and users can type the bucket name manually when setting
      # up a compute environment. To allow Seqera to fetch the list of buckets in the
      # account, the s3:ListAllMyBuckets action can be added, and it must have the
      # Resource field set to *, as shown in the generic policy at the beginning of this document.
      #
      # Seqera offers several products to manipulate data on AWS S3 buckets, such as
      # Studios and Data Explorer; if these features are not used the related permissions can be omitted.
      #
      # The IAM policy can be scoped down to only allow limited read/write permissions in
      # certain S3 buckets used by Studios/Data Explorer. In addition, the policy must
      # include permission to check the region and list the content of the S3 bucket
      # used as Nextflow work directory. We also recommend granting the s3:GetObject
      # permission on the work directory path to fetch Nextflow log files.
      {
        Sid    = "OptionalS3PlatformDataAccessCanBeRestricted"
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:PutObject",
        ]
        Resource = "*"
      },

      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#iam-roles-for-aws-batch-optional
      # Seqera can automatically create the IAM roles needed to interact with AWS Batch and
      # other AWS services. You can opt out of this behavior by creating the required IAM roles
      # manually and providing their ARNs during compute environment creation in Platform: refer
      # to the documentation for more details on how to manually set up IAM roles.
      {
        Sid    = "OptionalIAMManagementCanBeRestricted"
        Effect = "Allow"
        Action = [
          "iam:AddRoleToInstanceProfile",
          "iam:AttachRolePolicy",
          "iam:CreateInstanceProfile",
          "iam:CreateRole",
          "iam:DeleteInstanceProfile",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetRole",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PutRolePolicy",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:TagRole",
        ]
        Resource = [
          "arn:aws:iam::*:role/${var.tower_forge_prefix}*",
          "arn:aws:iam::*:instance-profile/${var.tower_forge_prefix}*",
        ]
      },

      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#aws-systems-manager-optional
      # Seqera Platform can interact with AWS Systems Manager (SSM) to identify ECS Optimized AMIs
      # for pipeline execution. This permission is optional, meaning that a custom AMI ID can be
      # provided at compute environment creation, removing the need for this permission.
      {
        Sid      = "OptionalFetchOptimizedAMIMetadata"
        Effect   = "Allow"
        Action   = "ssm:GetParameters"
        Resource = "arn:aws:ssm:*:*:parameter/aws/service/ecs/*"
      },

      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#ec2-describe-permissions-optional
      # Seqera can interact with EC2 to retrieve information about existing AWS resources in your
      # account, including VPCs, subnets, and security groups. This data is used to populate dropdown
      # menus in the Platform UI when creating new compute environments. While these permissions are
      # optional, they are recommended to enhance the user experience. Without these permissions,
      # resource ARNs need to be manually entered in the interface by the user.

      /* GIVEN WE CREATE COMPUTE ENVS VIA TERRAFORM - WE DISABLE THIS */
      /*{
        Sid    = "OptionalEC2MetadataDescribe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
        ]
        Resource = "*"
      }, */

      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#fsx-file-systems-optional
      # Seqera can manage AWS FSx file systems, if needed by the pipelines.
      #
      # This section of the policy is optional and can be omitted if FSx file systems are not used
      # by your pipelines. The describe actions cannot be restricted to specific resources, so permission
      # to operate on any resource * must be granted. The management actions can be restricted
      # to specific resources, like in the example below.

      # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#pipeline-secrets-optional
      # Seqera can synchronize pipeline secrets defined on the Platform workspace with AWS Secrets
      # Manager, which requires additional permissions on the IAM user. If you do not plan to
      # use pipeline secrets, you can omit this section of the policy.
      #
      # The listing of secrets cannot be restricted, but the management actions can be restricted
      # to only allow managing secrets in a specific account and region, which must be the same
      # region where the pipeline runs. Note that Seqera only creates secrets with the tower- prefix.
      {
        Sid      = "OptionalPipelineSecretsListing"
        Effect   = "Allow"
        Action   = "secretsmanager:ListSecrets"
        Resource = "*"
      },
      {
        Sid    = "OptionalPipelineSecretsManagementCanBeRestricted"
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:CreateSecret",
        ]
        Resource = "arn:aws:secretsmanager:*:*:secret:tower-*"
      },
    ],
    # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#efs-file-systems-optional
    # Seqera can manage AWS EFS file systems, if needed by the pipelines.
    var.enable_efs ? [
      {
        Sid    = "OptionalEFSManagementCanBeRestricted"
        Effect = "Allow"
        Action = [
          "elasticfilesystem:CreateFileSystem",
          "elasticfilesystem:DeleteFileSystem",
          "elasticfilesystem:CreateMountTarget",
          "elasticfilesystem:DeleteMountTarget",
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeMountTargets",
          "elasticfilesystem:UpdateFileSystem",
          "elasticfilesystem:PutLifecycleConfiguration",
          "elasticfilesystem:TagResource",
        ]
        Resource = "*"
      },
    ] : [],
    # https://docs.seqera.io/platform-enterprise/compute-envs/aws-batch#fsx-file-systems-optional
    # Seqera can manage AWS FSx Lustre file systems, if needed by the pipelines.
    var.enable_fsx_lustre ? [
      {
        Sid    = "OptionalFSXManagementCanBeRestricted"
        Effect = "Allow"
        Action = [
          "fsx:CreateFileSystem",
          "fsx:DeleteFileSystem",
          "fsx:DescribeFileSystems",
          "fsx:TagResource",
        ]
        Resource = "*"
      },
    ] : [],
  )
  })
}
