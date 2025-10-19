output "sg_ids" {
  value = { for k, v in aws_security_group.sgs : k => v.id }
}
