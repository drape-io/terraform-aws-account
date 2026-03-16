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

run "test_close_on_deletion_default" {
  command = plan

  assert {
    condition     = aws_organizations_account.account[0].close_on_deletion == false
    error_message = "close_on_deletion should default to false"
  }
}

run "test_close_on_deletion_true" {
  command = plan

  variables {
    close_on_deletion = true
  }

  assert {
    condition     = aws_organizations_account.account[0].close_on_deletion == true
    error_message = "close_on_deletion should be true when set"
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
    condition     = aws_iam_role_policy_attachment.roles["s3-list-access"].role == "drape-dev-s3-list-access"
    error_message = "The policy attachment wasn't setup correctly"
  }

  assert {
    condition     = strcontains(aws_iam_policy.roles["s3-list-access"].policy, "s3:ListAllMyBuckets")
    error_message = "The access policy should contain s3:ListAllMyBuckets"
  }

  assert {
    condition     = output.role_arns != null
    error_message = "role_arns output should not be null when roles are created"
  }

  assert {
    condition     = output.role_names != null
    error_message = "role_names output should not be null when roles are created"
  }

  assert {
    condition     = output.policy_arns != null
    error_message = "policy_arns output should not be null when roles are created"
  }
}

run "test_use_context_for_name_false" {
  command = plan

  variables {
    use_context_for_name = false
    name                 = "my-custom-account"
    email                = "custom@test.com"
  }

  assert {
    condition     = aws_organizations_account.account[0].name == "my-custom-account"
    error_message = "The account name should use var.name directly when use_context_for_name is false"
  }

  assert {
    condition     = aws_organizations_account.account[0].email == "custom@test.com"
    error_message = "The email should use var.email directly when use_context_for_name is false"
  }
}

run "test_disabled" {
  command = plan

  variables {
    context = {
      enabled = false
      group   = "drape"
      env     = "dev"
    }
  }

  assert {
    condition     = length(aws_organizations_account.account) == 0
    error_message = "No account should be created when enabled is false"
  }

  assert {
    condition     = output.account_id == null
    error_message = "account_id output should be null when enabled is false"
  }

  assert {
    condition     = output.account_name == null
    error_message = "account_name output should be null when enabled is false"
  }
}
