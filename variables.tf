variable "email" {
  type        = string
  description = "The owner e-mail address"

  validation {
    condition     = can(regex("@", var.email))
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

# This was copied from `drape-io/terraform-null-context` since it'll be passed
# along to it.
variable "context" {
  type = object({
    enabled    = optional(bool)
    group      = optional(string)
    tenant     = optional(string)
    env        = optional(string)
    scope      = optional(string)
    attributes = optional(list(string))
    tags       = optional(map(string))
  })
  description = <<-EOT
    Used to pass an object of any of the variables used to this module.  It is
    used to seed the module with labels from another context.
  EOT
}

variable "account_iam_user_access_to_billing" {
  type        = string
  description = <<-EOT
  If set to `ALLOW`, IAM users have access account billing information if they
  have the required permissions. If set to `DENY`, then only the root user can.

  Default to `ALLOW` since we don't want to be using root users.
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
  Permission assignments. Group key is group.id, User key is email address,
  value is permission set ARN
  EOT
}

variable "default_roles" {
  # The statement object type is intentionally repeated for assume_role_policy
  # and access_policy — Terraform does not support type aliases.
  type = map(object({
    assume_role_policy = optional(object({
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
      }),
      description = string
    }))
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
      }),
      description = string
    })
  }))

  default     = null
  description = <<-EOT
  Default roles to create in the account after it is created.  This is useful
  when you want to create some standard roles for things like terraform and
  github actions.
  EOT
}

variable "assume_role" {
  type        = string
  default     = "OrganizationAccountAccessRole"
  description = "The default role generated in every subaccount so the management account can assume into it."
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region for the subaccount provider."
}

variable "close_on_deletion" {
  type        = bool
  default     = false
  description = "Whether to close the account on deletion. If false, the account will be removed from the organization but not closed."
}

variable "use_context_for_name" {
  type        = bool
  default     = true
  description = "If you set to false it'll use var.name and var.email instead of dynamically generating one from the context"
}
