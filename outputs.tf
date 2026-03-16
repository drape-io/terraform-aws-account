output "account_id" {
  value       = try(aws_organizations_account.account[0].id, null)
  description = "The unique identifier (ID) of the account."
}

output "account_name" {
  value       = try(aws_organizations_account.account[0].name, null)
  description = "The name of the account."
}

output "role_arns" {
  value       = { for k, v in aws_iam_role.roles : k => v.arn }
  description = "Map of role name to ARN for all created IAM roles."
}

output "role_names" {
  value       = { for k, v in aws_iam_role.roles : k => v.name }
  description = "Map of role key to name for all created IAM roles."
}

output "policy_arns" {
  value       = { for k, v in aws_iam_policy.roles : k => v.arn }
  description = "Map of role key to policy ARN for all created IAM policies."
}
