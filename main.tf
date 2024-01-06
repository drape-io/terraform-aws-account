resource "aws_organizations_account" "account" {
  count                      = local.context.enabled ? 1 : 0
  email                      = "${local.email_user}+${local.name}@${local.email_domain}"
  name                       = local.name
  tags                       = local.context.tags
  parent_id                  = var.ou_id
  iam_user_access_to_billing = var.account_iam_user_access_to_billing
  close_on_deletion          = true

  lifecycle {
    ignore_changes = [iam_user_access_to_billing]
  }
}

data "aws_ssoadmin_instances" "sso" {
  count = local.context.enabled && var.permission_assignments != null ? 1 : 0
}

resource "aws_ssoadmin_account_assignment" "group_access" {
  for_each           = local.context.enabled && var.permission_assignments != null ? lookup(var.permission_assignments, "groups", {}) : {}
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso[0].arns)[0]
  permission_set_arn = each.value.permission_set_arn
  principal_id       = each.value.group_id
  principal_type     = "GROUP"

  target_id   = aws_organizations_account.account[0].id
  target_type = "AWS_ACCOUNT"
}

data "aws_identitystore_user" "users" {
  for_each          = local.context.enabled && var.permission_assignments != null ? lookup(var.permission_assignments, "users", {}) : {}
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso[0].identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = each.key
    }
  }
}
resource "aws_ssoadmin_account_assignment" "user_access" {
  for_each           = local.context.enabled && var.permission_assignments != null ? lookup(var.permission_assignments, "users", {})  : {}
  instance_arn       = tolist(data.aws_ssoadmin_instances.sso[0].arns)[0]
  permission_set_arn = each.value
  principal_id       = data.aws_identitystore_user.users[each.key].user_id
  principal_type     = "USER"

  target_id   = aws_organizations_account.account[0].id
  target_type = "AWS_ACCOUNT"
}
