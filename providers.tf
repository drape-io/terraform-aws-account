data "aws_organizations_organization" "org" {}
data "aws_partition" "current" {}

provider "aws" {
  alias   = "subaccount"
  region  = var.region
  dynamic "assume_role" {
    for_each = data.aws_organizations_organization.org.master_account_id != aws_organizations_account.account[0].id ? [var.assume_role] : []
    content {
      role_arn     = "arn:${data.aws_partition.current.partition}:iam::${aws_organizations_account.account[0].id}:role/${var.assume_role}"
      session_name = "PREP_ROLES"
    }
  }
}

/* This is the default role that is generated in every subaccount so the master
account can assume into it. */
variable "assume_role" {
  type    = string
  default = "OrganizationAccountAccessRole"
}

variable "region" {
  type    = string
  default = "us-east-1"
}