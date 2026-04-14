# AWS Seqera IAM Setup

A Terraform module for the pre-initialisation of IAM resources for use
by Seqera workspaces.

The rationale for this module is that some organisations may prevent
the creation of IAM principals as part of routine Terraforming
(this is true for our AWS organisation – in which the single PlatformOwner
is the only user who can create IAM principals). 

This module allows the easy creation of a single IAM principal, IAM access key and corresponding
secret – as a one-off operation in any account. Because Seqera credentials are properties of workspaces themselves,
we have to provide access to the raw IAM access key and secret
in order that we can create Seqera credentials *after* we Terraform
the workspace.

All Seqera workspace deployments in this model share in the use of
the same IAM principal.
