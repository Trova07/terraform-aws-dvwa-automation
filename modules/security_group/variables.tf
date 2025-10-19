variable "vpc_id" {
  type        = string
  description = "id of vpc"
}

variable "sg_list" {
  description = "보안그룹들"

  type = map(object({
    ingress_rules = map(object({
      protocol    = string
      from_port   = number
      to_port     = number
      cidr_blocks = list(string)
    }))
    egress_rules = map(object({
      protocol    = string
      from_port   = number
      to_port     = number
      cidr_blocks = list(string)
    }))
  }))
}