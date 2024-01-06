provider "aws" {
  access_key = "dev-tfstate-backend"
  secret_key = "dev-tfstate-backend"
  region     = "us-east-1"

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_use_path_style
  # s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam            = "http://localhost:4566"
    kms            = "http://localhost:4566"
    organizations  = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    sts            = "http://localhost:4566"
    ssoadmin       = "http://localhost:4566"
  }
}

provider "aws" {
  alias      = "subaccount"
  access_key = "dev-tfstate-backend"
  secret_key = "dev-tfstate-backend"
  region     = "us-east-1"

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_use_path_style
  # s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam            = "http://localhost:4566"
    kms            = "http://localhost:4566"
    organizations  = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    sts            = "http://localhost:4566"
    ssoadmin       = "http://localhost:4566"
  }
}

variables {
  context = {
    group = "drape"
    env   = "dev"
  }
  email = "group-sre@test.com"
  name  = "security"
}

run "setup" {
  module {
    source = "./tests/setup"
  }
}

run "test_create_account" {
  command = plan

  assert {
    condition     = aws_organizations_account.account[0].name == "drape-dev-security"
    error_message = "The account was named wrong"
  }

  assert {
    condition     = aws_organizations_account.account[0].email == "group-sre+drape-dev-security@test.com"
    error_message = "The e-mail was wrong."
  }
}

run "test_default_roles" {
  command = plan

  variables {
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
                      "arn:aws:iam::123456789:root"
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

  assert {
    condition     = aws_iam_role.roles["s3-list-access"].name == "drape-dev-s3-list-access"
    error_message = "The first role wasn't created"
  }

  assert {
    condition     = strcontains(aws_iam_role.roles["s3-list-access"].assume_role_policy, "123456789")
    error_message = "The assume role wasn't setup correctly"
  }

  assert {
    condition     = length(aws_iam_policy_attachment.roles["s3-list-access"].roles) == 1
    error_message = "The policy attachment wasn't setup correctly"
  }
}