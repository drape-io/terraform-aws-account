variable "email" {
  description = "The owner e-mail address"
}

variable "name" {
  description = "The name of the account"
}

variable "ou_id" {
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
}

variable "permission_assignments" {
  type = object({
    groups = map(object({
      permission_set_arn = string
      group_id           = string
    }))
    users = map(string)
  })

  default     = null
  description = <<-EOT
  Permission assignments. Group key is group.id, User key is email address,
  value is permission set ARN
  EOT
}

variable "default_roles" {
  /*
  {
    "s3-full-access": {
        "assume_role_policy": {
            description: ...,
            policy: ...,
        },
        "access_policy": {
            description: ...,
            policy: ...,
        }
    }
  }
  */
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
      policy : object({
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
      description : string
    })
  }))

  default     = null
  description = <<-EOT
  Default roles to create in the account after it is created.  This is useful
  when you want to create some standard roles for things like terraform and
  github actions.
  EOT
}
