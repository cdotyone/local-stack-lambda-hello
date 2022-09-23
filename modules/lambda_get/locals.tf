locals {
  tags = merge({
    terraform = true
  }, var.tags)
  name = var.name
}