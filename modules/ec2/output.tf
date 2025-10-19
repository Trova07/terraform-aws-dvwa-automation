output "ec2_instance_ids" {
  #   value = [ for i in range(length(aws_instance.public_ec2s)) : aws_instance.public_ec2s[i].id] 
  value = [for i, v in aws_instance.public_ec2s : v.id]
}
 