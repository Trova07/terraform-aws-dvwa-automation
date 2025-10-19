variable "public_subnet_ids" {
  type        = list(string)
  description = "list of public subnets' ids"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "list of private subnets' ids"
}

variable "region_name" {
  type        = string
  description = "region_name"
}

variable "sg_ids" {
  type = map(string)
}

variable "key_name" {
  type        = string
  description = "keypair name"
}
variable "ec2_instances" {
  description = "EC2 instances"
  type = map(object(
    {
      count         = number
      sg_names      = list(string)
      ami_id        = string
      instance_type = string
      public        = bool
    }
  ))
}


