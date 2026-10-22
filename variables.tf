variable "email" {
  type        = string
  description = "The owner e-mail address"

  validation {
    condition     = strcontains(var.email, "@")
    error_message = "Must be a valid email address containing @."
  }
}

variable "name" {
  type        = string
  description = "The name of the account"
}

variable "ou_id" {
  type        = string
  default     = null
  description = "The organizational unit to place the account under"
}

# Mirrors the `context` input of terraform-null-context, which receives it.
variable "context" {
  type = object({
    enabled        = optional(bool)
    group          = optional(string)
    tenant         = optional(string)
    env            = optional(string)
    scope          = optional(string)
    attributes     = optional(list(string))
    tags           = optional(map(string))
    tag_key_case   = optional(string)
    tag_value_case = optional(string)
  })
  description = <<-EOT
    A terraform-null-context object. The module takes its labels and tags
    from this context.
  EOT
}

variable "account_iam_user_access_to_billing" {
  type        = string
  description = <<-EOT
  If set to `ALLOW`, IAM users have access to account billing information if they
  have the required permissions. If set to `DENY`, then only the root user can.

  The default is `ALLOW`, so that billing access does not need the root user.

  The module sets this value when it creates the account and ignores later
  changes.
  EOT
  default     = "ALLOW"

  validation {
    condition     = contains(["ALLOW", "DENY"], var.account_iam_user_access_to_billing)
    error_message = "Must be ALLOW or DENY."
  }
}

variable "permission_assignments" {
  type = object({
    groups = optional(map(object({
      permission_set_arn = string
      group_id           = string
    })), {})
    users = optional(map(string), {})
  })

  default     = null
  description = <<-EOT
  IAM Identity Center permission assignments for the account.
  `groups` maps an arbitrary label to `{ permission_set_arn, group_id }`.
  `users` maps an Identity Store `UserName` to a permission set ARN.
  EOT
}

variable "default_roles" {
  # The statement object type is intentionally repeated for assume_role_policy
  # and access_policy, because Terraform does not support type aliases.
  type = map(object({
    assume_role_policy = object({
      policy = object({
        policy_id = optional(string, null)
        version   = optional(string, null)
        statements = list(object({
          sid           = optional(string, null)
          effect        = optional(string, null)
          actions       = optional(list(string), null)
          not_actions   = optional(list(string), null)
          resources     = optional(list(string), null)
          not_resources = optional(list(string), null)
          conditions = optional(list(object({
            test     = string
            variable = string
            values   = list(string)
          })), [])
          principals = optional(list(object({
            type        = string
            identifiers = list(string)
          })), [])
          not_principals = optional(list(object({
            type        = string
            identifiers = list(string)
          })), [])
        }))
      })
      description = string
    })
    access_policy = object({
      policy = object({
        policy_id = optional(string, null)
        version   = optional(string, null)
        statements = list(object({
          sid           = optional(string, null)
          effect        = optional(string, null)
          actions       = optional(list(string), null)
          not_actions   = optional(list(string), null)
          resources     = optional(list(string), null)
          not_resources = optional(list(string), null)
          conditions = optional(list(object({
            test     = string
            variable = string
            values   = list(string)
          })), [])
          principals = optional(list(object({
            type        = string
            identifiers = list(string)
          })), [])
          not_principals = optional(list(object({
            type        = string
            identifiers = list(string)
          })), [])
        }))
      })
      description = string
    })
  }))

  default     = null
  description = <<-EOT
  IAM roles to create in the new account, for example standard roles for
  Terraform and GitHub Actions.
  EOT
}

variable "assume_role" {
  type        = string
  default     = "OrganizationAccountAccessRole"
  description = "The role the management account assumes in the new account to create default_roles. It must match the role that AWS created with the account (OrganizationAccountAccessRole unless the account was created with a different role_name)."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for the subaccount provider."
}

variable "close_on_deletion" {
  type        = bool
  default     = false
  description = "Whether to close the account on deletion. If false, Terraform removes the account from the organization but does not close it. AWS allows that removal only after the account has the details it needs to run as a standalone account, such as a payment method."
}

variable "use_context_for_name" {
  type        = bool
  default     = true
  description = "If false, the module uses var.name and var.email as given instead of deriving them from the context."
}
