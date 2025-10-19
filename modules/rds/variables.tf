variable "rds_subnet_group" {
  description = "db subnet group information"
  type = object({
    name        = string
    description = string
  })
}

variable "subnet_ids" {
  type = list(string)
}

variable "db_instance" {
  type = object({
    engine              = string
    engine_version      = string
    identifier          = string
    snapshot_identifier = string
    username            = string
    password            = string
    instance_class      = string
    storage_type        = string
    allocated_storage   = number
    multi_az            = bool
    publicly_accessible = bool
    sg_names            = list(string)
    source_db_identifer = string
    latest_snapshot     = bool
  })
}

variable "sg_ids" {
  type = map(string)
}
