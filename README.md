# terraform-aws-account
Terraform module to help easily provision accounts

# Usage

```hcl
data "aws_partition" "current" {}

module "deployment" {
  source  = "../../../drape/terraform-aws-account"
  name    = "deployment"
  context = local.context
  email   = local.email
  ou_id   = aws_organizations_organizational_unit.infrastructure.id
}

locals {
  default_roles = {
    s3-list-access = {
      assume_role_policy = {
        description : "Allow management account to assume S3 list access"
        policy : {
          statements = [
            {
              effect  = "Allow"
              actions = ["sts:AssumeRole"]
              principals = [
                {
                  type = "AWS"
                  identifiers = [
                    "arn:${data.aws_partition.current.partition}::iam::${module.deployment.account_id}:root"
                  ]
                }
              ]
            }

          ]
        }
      }
      access_policy = {
        description : "Give role access to s3",
        policy : {
          statements = [
            {
              effect    = "Allow"
              actions   = ["s3:ListAllMyBuckets"]
              resources = ["*"]
            }
          ]
        }
      }
    }
  }
}


module "security" {
  source        = "github.com/drape-io/terraform-aws-account"
  name          = "security"
  context       = {"env": "sec"}
  email         = "group-sre@test.com"
  default_roles = local.default_roles
}
```