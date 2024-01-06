locals {
  roles = local.context.enabled && var.default_roles != null ? var.default_roles : {}

  assume_roles = {
    for role, value in local.roles :
    role => value.assume_role_policy.policy
    if lookup(value, "assume_role_policy", null) != null
  }
  access_policies = {
    for role, value in local.roles :
    role => value.access_policy.policy
  }
}

data "aws_iam_policy_document" "assume" {
  for_each = length(local.assume_roles) > 0 ? local.assume_roles : {}

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

data "aws_iam_policy_document" "access" {
  for_each = length(local.access_policies) > 0 ? local.access_policies : {}

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
  for_each           = local.context.enabled ? local.assume_roles : {}
  name               = format("%s-%s", module.ctx.id_full, each.key)
  description        = var.default_roles[each.key].assume_role_policy.description
  assume_role_policy = data.aws_iam_policy_document.assume[each.key].json
  tags               = module.ctx.tags
}

resource "aws_iam_policy" "roles" {
  for_each    = local.context.enabled ? local.access_policies : {}
  name        = format("%s-%s", module.ctx.id_full, each.key)
  description = var.default_roles[each.key].access_policy.description
  policy      = data.aws_iam_policy_document.access[each.key].json
  provider    = aws.subaccount
  tags        = module.ctx.tags
}

resource "aws_iam_policy_attachment" "roles" {
  for_each   = local.context.enabled ? local.access_policies : {}
  name       = format("%s-%s", module.ctx.id_full, each.key)
  roles      = ["${aws_iam_role.roles[each.key].name}"]
  policy_arn = aws_iam_policy.roles[each.key].arn
  provider   = aws.subaccount
}
