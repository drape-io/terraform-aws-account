locals {
  context      = module.ctx.context
  split_email  = split("@", var.email)
  email_user   = element(local.split_email, 0)
  email_domain = element(local.split_email, 1)
  name         = format("%s-%s", module.ctx.id_full, var.name)
}
