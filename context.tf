module "ctx" {
  source  = "github.com/drape-io/terraform-null-context?ref=d1d684d0312da9ed43e3efb2ff9c2d11a39b1bb9"
  context = var.context
}