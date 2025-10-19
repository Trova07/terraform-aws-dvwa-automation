variable "launch_template" {
  type = map(object({
    name_prefix   = string
    description   = string
    image_id      = string
    instance_type = string
    key_name      = string
    sg_names      = list(string)
    user_data     = string
    network_interfaces = object({
      associate_public_ip_address = bool
      delete_on_termination       = bool
    })
  }))
}

variable "sg_ids" {
  type = map(string)
}
