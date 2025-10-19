variable "region" {
  description = "aws region"
  type        = string
  default     = "ap-northeast-2"
}

variable "cidr_block" {
  description = "aws vpc의 cidr block"
  type        = string
  default     = "10.2.0.0/24"
}

variable "region_name" {
  description = "AWS vpc의 이름"
  type        = string
}

variable "number_of_public_subnets" {
  description = "Vpc의 public subnet의 갯수"
  type        = number
}

variable "number_of_private_subnets" {
  description = "Vpc의 public subnet의 갯수"
  type        = number
}

variable "az_list" {
  description = "aws region의 가용영역 목록"
  type        = list(string)
}

variable "number_of_azs" {
  type        = number
  description = "availabilty zones의 수"
}

variable "subnet_bits" {
  type        = number
  description = "aws vpc의 subnet bits 수"
}

variable "number_of_nat_gws" {
  type = number
}