variable "name_prefix" {
  type        = string
  default     = "seqera"
  description = "Prefix applied to all named resources (IAM user, group, policy, secret). Change this if you need multiple instances in the same account. The default of 'seqera' should be used normally."
}

variable "tower_forge_prefix" {
  type        = string
  default     = "TowerForge-"
  description = "The TowerForge resource name prefix configured in Seqera Enterprise. The default of 'TowerForge-' should be used normally."
}

variable "enable_efs" {
  type        = bool
  default     = false
  description = "When true, adds EFS management permissions (elasticfilesystem:Create/Delete/Describe/Update/Mount/Tag) to the Seqera IAM policy."
}

variable "enable_fsx_lustre" {
  type        = bool
  default     = false
  description = "When true, adds FSx Lustre management permissions (fsx:CreateFileSystem, fsx:DeleteFileSystem, fsx:DescribeFileSystems, fsx:TagResource) to the Seqera IAM policy."
}

variable "admin_principal_arns" {
  type    = list(string)
  default = null
  description = <<-EOT
    List of IAM principal ARN patterns (supports wildcards) that are allowed to
    read and write the Seqera IAM secret. All other principals are explicitly
    denied via a resource-based secret policy. Defaults to the AWSAdministratorAccess
    and PlatformOwnerAccess SSO roles in the current account.
  EOT
}