variable "key_info" {
  type = object({
    algorithm = string
    rsa_bits  = number
  })
  default = {
    algorithm = "RSA"
    rsa_bits  = 2048
  }
}
variable "region_name" {
  type = string
}