output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

output "private_subnet_ids" {
  value = local.private_subnet_ids
}

output "route_privates" {
  value = local.route_privates
}
