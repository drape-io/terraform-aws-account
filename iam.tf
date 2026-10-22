locals {
  roles = module.ctx.enabled && var.default_roles != null ? var.default_roles : {}

  # Merge both policy types into a single map so we only need one
  # aws_iam_policy_document resource with one copy of the dynamic block.
  all_policies = merge(
    { for k, v in local.roles : "assume/${k}" => v.assume_role_policy.policy },
    { for k, v in local.roles : "access/${k}" => v.access_policy.policy },
  )
}

data "aws_iam_policy_document" "this" {
  for_each = local.all_policies

  policy_id = each.value.policy_id
  version   = each.value.version

  dynamic "statement" {
    for_each = each.value.statements

    content {
      sid    = statement.value.sid
      effect = statement.value.effect

      actions     = statement.value.actions
      not_actions = statement.value.not_actions

      resources     = statement.value.resources
      not_resources = statement.value.not_resources

      dynamic "principals" {
        for_each = statement.value.principals

        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      dynamic "not_principals" {
        for_each = statement.value.not_principals

        content {
          type        = not_principals.value.type
          identifiers = not_principals.value.identifiers
        }
      }

      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role" "roles" {
  for_each           = local.roles
  name               = format("%s-%s", module.ctx.id_full, each.key)
  description        = each.value.assume_role_policy.description
  assume_role_policy = data.aws_iam_policy_document.this["assume/${each.key}"].json
  tags               = module.ctx.tags
  provider           = aws.subaccount
}

resource "aws_iam_policy" "roles" {
  for_each    = local.roles
  name        = format("%s-%s", module.ctx.id_full, each.key)
  description = each.value.access_policy.description
  policy      = data.aws_iam_policy_document.this["access/${each.key}"].json
  provider    = aws.subaccount
  tags        = module.ctx.tags
}

resource "aws_iam_role_policy_attachment" "roles" {
  for_each   = local.roles
  role       = aws_iam_role.roles[each.key].name
  policy_arn = aws_iam_policy.roles[each.key].arn
  provider   = aws.subaccount
}
