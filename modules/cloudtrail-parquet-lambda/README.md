# CloudTrail Parquet Lambda module

A terraform module to deploy a lambda function that
converts CloudTrail events to Parquet format and stores them in S3.

## Usage

```terraform
module "cloudtrail_parquet_lambda" {
  source = "git::https://github.com/umccr/terraform-common.git//modules/cloudtrail-parquet-lambda?ref=cloudtrail-parquet-lambda/v0.1.0"

  aws_region = "ap-southeast-2"

  ghcr_repo = "ghcr.io/umccr/cloudtrail-parquet-lambda"
  ghcr_tag  = "2.0.0"

  cloudtrail_base_input_path  = "s3://${aws_s3_bucket.cloudtrail_root.id}/"
  cloudtrail_base_output_path = "s3://${aws_s3_bucket.cloudtrail_root.id}/"
  organisation_id             = "o-abcdefghi"
  account_ids                 =  ["1234567890", "0123456789"]
}
```
