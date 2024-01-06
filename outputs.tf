output "account_id" {
  value       = aws_organizations_account.account[0].id
  description = "The unique identifier (ID) of the account."
}