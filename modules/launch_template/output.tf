output "launch_template_versions" {
  value = {
    for key, lt in aws_launch_template.example :
    key => lt.default_version
  }
}

output "launch_template_ids" {
  value = {
    for k, i in aws_launch_template.example :
    i.tags.Name => i.id
  }
}

output "launch_template_resource" {
  value = aws_launch_template.example
}