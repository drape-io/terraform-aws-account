locals {
  context      = module.ctx.context
  split_email  = split("@", var.email)
  email_user   = element(local.split_email, 0)
  email_domain = element(local.split_email, 1)

  email = var.use_context_for_name ? "${local.email_user}+${local.name}@${local.email_domain}" : var.email
  name  = var.use_context_for_name ? format("%s-%s", module.ctx.id_full, var.name) : var.name
}
