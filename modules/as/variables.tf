variable "public_subnet_ids" {
  type = list(string)
}

variable "autoscaling_group" {
  type = map(object({
    name                      = string
    desired_capacity          = number
    min_size                  = number
    max_size                  = number
    health_check_type         = string
    health_check_grace_period = number
  }))
}

variable "launch_template_ids" {
  type = map(string)
}

variable "id_gnuboard" {
  type    = string
  default = null
}

variable "id_dvwa" {
  type = string
}
variable "id_elasticsearch1" {
  type    = string
  default = null
}

variable "id_elasticsearch2" {
  type    = string
  default = null
}

variable "autoscaling_policy" {
  type = object({
    name                      = string
    estimated_instance_warmup = number
    policy_type               = string
    predefined_metric_type    = string
    target_value              = number
  })
}
