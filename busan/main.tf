terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

locals {
  value1           = "test1"
  config           = yamldecode(file("./data.yml"))
  user_data_script = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1><strong>Machete</strong></h1> <img src=\"https://i.namu.wiki/i/KBSn2pg8ryHDNztygUbIBy026n9rLWGh49F2F1A6UEJQ12eseuLRLm0SrBve2oFWGSq2ymTzxNXbTUDd7I2QKzTt-bN6TgWBZtn-yNsP2FlZE1fipqWotgkgDH9tfa4EGIfsGdGFwCtEfOWv8ImvmA.webp\">" > /var/www/html/index.html
  EOF

  user_data_encoded = base64encode(local.user_data_script)
}

provider "aws" {
  region = local.config.region
}

module "vpc" {
  source      = "../modules/vpc"
  region      = local.config.region
  region_name = local.config.region_name

  az_list       = ["ap-northeast-2a", "ap-northeast-2c", "ap-northeast-2d"]
  number_of_azs = local.config.number_of_azs

  cidr_block                = local.config.network.cidr_block
  subnet_bits               = local.config.network.subnet_bits
  number_of_public_subnets  = local.config.network.number_of_public_subnets
  number_of_private_subnets = local.config.network.number_of_private_subnets
  number_of_nat_gws         = local.config.network.number_of_nat_gws
}

module "security_group" {
  source  = "../modules/security_group"
  sg_list = local.config.sg_list
  vpc_id  = module.vpc.vpc_id
} 

module "keypair" {
  source = "../modules/keypair"

  key_info    = local.config.key_info
  region_name = local.config.region_name
} 

module "launch_template" {
  source = "../modules/launch_template"

  launch_template = local.config.launch_template
  sg_ids          = module.security_group.sg_ids
}

module "ec2" {
  source = "../modules/ec2"

  region_name        = local.config.region_name
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  sg_ids             = module.security_group.sg_ids
  key_name           = module.keypair.key_name
  ec2_instances      = local.config.ec2_instances
}

# module "as" {
#   source = "../modules/as"

#   public_subnet_ids   = module.vpc.public_subnet_ids
#   autoscaling_policy  = local.config.autoscaling_policy
#   autoscaling_group   = local.config.autoscaling_group
#   launch_template_ids = module.launch_template.launch_template_ids
#   id_dvwa             = module.launch_template.launch_template_ids["dvwa-filebeat"]
# }  
 
module "rds" {
  source = "../modules/rds"

  sg_ids           = module.security_group.sg_ids
  db_instance      = local.config.db_instance
  rds_subnet_group = local.config.rds_subnet_group
  subnet_ids       = module.vpc.private_subnet_ids
}  

resource "local_file" "keypa1r" {
  content              = module.keypair.private_key
  filename             = "./id_ed25519"
  file_permission      = "0600"
  directory_permission = "0700"
} 

resource "aws_route53_record" "dvwa" {
  zone_id = "Z032662211JM2TEXY5ZXL"
  name    = "db.f1.it-edu.org"
  type    = "CNAME"
  records = [ module.rds.rds ]
  ttl     = 60
} 
