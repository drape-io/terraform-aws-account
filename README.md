# terraform-aws-account

Terraform module for provisioning AWS Organizations sub-accounts with optional IAM roles and AWS Identity Center (SSO) permission assignments.

## Prerequisites

- AWS Organizations enabled in the management account
- AWS Identity Center (SSO) configured if using `permission_assignments`
- Management account credentials with permissions to create accounts

## Usage

### Basic Account

```hcl
module "deployment" {
  source  = "github.com/drape-io/terraform-aws-account"
  name    = "deployment"
  context = local.context
  email   = "group-sre@example.com"
  ou_id   = aws_organizations_organizational_unit.infrastructure.id
}
```

When `use_context_for_name` is `true` (the default), the module constructs the account name and email from the context. For example, with `context = { group = "drape", env = "dev" }`, `name = "security"`, and `email = "group-sre@example.com"`:

- Account name becomes: `drape-dev-security`
- Email becomes: `group-sre+drape-dev-security@example.com`

### Account with Default Roles

```hcl
data "aws_organizations_organization" "org" {}

locals {
  # The management account ID — roles in subaccounts trust this account
  management_account_id = data.aws_organizations_organization.org.master_account_id

  default_roles = {
    s3-list-access = {
      assume_role_policy = {
        description = "Allow management account to assume S3 list access"
        policy = {
          statements = [
            {
              effect  = "Allow"
              actions = ["sts:AssumeRole"]
              principals = [
                {
                  type        = "AWS"
                  identifiers = ["arn:aws:iam::${local.management_account_id}:root"]
                }
              ]
            }
          ]
        }
      }
      access_policy = {
        description = "Give role access to S3"
        policy = {
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
  context       = { group = "drape", env = "sec" }
  email         = "group-sre@example.com"
  default_roles = local.default_roles
}
```

### Account with SSO Permission Assignments

```hcl
module "platform" {
  source  = "github.com/drape-io/terraform-aws-account"
  name    = "platform"
  context = local.context
  email   = "group-sre@example.com"

  # Both groups and users are optional — pass only what you need
  permission_assignments = {
    groups = {
      admins = {
        permission_set_arn = aws_ssoadmin_permission_set.admin.arn
        group_id           = aws_identitystore_group.admins.group_id
      }
    }
  }
}
```

## Context System

This module uses [terraform-null-context](https://github.com/drape-io/terraform-null-context) for consistent naming and tagging. The `context` variable accepts:

| Field        | Description                    |
|-------------|-------------------------------|
| `enabled`    | Whether to create resources    |
| `group`      | Group name (e.g. org name)     |
| `tenant`     | Tenant identifier              |
| `env`        | Environment (e.g. dev, prod)   |
| `scope`      | Scope identifier               |
| `attributes` | Additional name attributes     |
| `tags`       | Tags to apply to all resources |

Set `use_context_for_name = false` to use `var.name` and `var.email` directly instead of deriving them from context.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | The name of the account | `string` | — | yes |
| `email` | The owner e-mail address | `string` | — | yes |
| `context` | Context object for naming and tagging | `object` | — | yes |
| `ou_id` | The organizational unit to place the account under | `string` | `null` | no |
| `account_iam_user_access_to_billing` | Allow IAM users access to billing (`ALLOW` or `DENY`) | `string` | `"ALLOW"` | no |
| `permission_assignments` | SSO permission assignments for groups and users | `object` | `null` | no |
| `default_roles` | IAM roles to create in the account | `map(object)` | `null` | no |
| `assume_role` | Role name for cross-account access | `string` | `"OrganizationAccountAccessRole"` | no |
| `region` | AWS region | `string` | `"us-east-1"` | no |
| `close_on_deletion` | Whether to close the account on deletion | `bool` | `false` | no |
| `use_context_for_name` | Derive name/email from context | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `account_id` | The unique identifier (ID) of the account |
| `account_name` | The name of the account |
| `role_arns` | Map of role key to ARN for all created IAM roles |
| `role_names` | Map of role key to name for all created IAM roles |
| `policy_arns` | Map of role key to policy ARN for all created IAM policies |

## Testing

Tests use [LocalStack Pro](https://localstack.cloud/) (Organizations is a pro feature).

```bash
# Set your LocalStack auth token
export LOCALSTACK_AUTH_TOKEN="your-token"

# Start LocalStack
docker compose up -d

# Run tests
terraform init
terraform test
```

## License

Mozilla Public License 2.0
