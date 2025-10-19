locals {
  value1 = "test1"
  config = yamldecode(file("./data.yml"))
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

module "as" {
  source = "../modules/as"

  public_subnet_ids   = module.vpc.public_subnet_ids
  autoscaling_policy  = local.config.autoscaling_policy
  autoscaling_group   = local.config.autoscaling_group
  launch_template_ids = module.launch_template.launch_template_ids
  id_gnuboard         = module.launch_template.launch_template_ids["gnuboard"]
  id_dvwa             = module.launch_template.launch_template_ids["dvwa-filebeat"]
  id_elasticsearch1   = module.launch_template.launch_template_ids["elasticsearch1"]
  id_elasticsearch2   = module.launch_template.launch_template_ids["elasticsearch2"]
}

module "rds" {
  source = "../modules/rds"

  sg_ids           = module.security_group.sg_ids
  db_instance      = local.config.db_instance
  rds_subnet_group = local.config.rds_subnet_group
  subnet_ids       = module.vpc.private_subnet_ids
}

resource "aws_instance" "suricata" {
  ami                         = "ami-0acff2a4c8c1d9887"
  instance_type               = "t3.small"
  key_name                    = "seoul-ed25519-key"
  subnet_id                   = module.vpc.public_subnet_ids[0]
  security_groups             = [for name in ["ids"] : module.security_group.sg_ids[name]]
  associate_public_ip_address = false
  tags = {
    Name = "ids-suricata"
  }

  user_data = <<-EOT
  #!/bin/bash
  hostnamectl hostname ids.f1.it-edu.org

  systemctl start suricata
  systemctl restart filebeat

  EOT
}

resource "aws_ec2_traffic_mirror_target" "target" {
  network_interface_id = aws_instance.suricata.primary_network_interface_id
  description          = "Traffic Mirror Target"
}

resource "aws_ec2_traffic_mirror_filter" "filter" {
  description = "Traffic Mirror Filter"
}

resource "aws_ec2_traffic_mirror_filter_rule" "ingress1" {
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  rule_action              = local.config.mirror_traffic_filter.ingress_rules.icmp.rule_action
  rule_number              = local.config.mirror_traffic_filter.ingress_rules.icmp.rule_number
  traffic_direction        = local.config.mirror_traffic_filter.ingress_rules.icmp.traffic_direction
  destination_cidr_block   = local.config.mirror_traffic_filter.ingress_rules.icmp.destination_cidr_block
  source_cidr_block        = local.config.mirror_traffic_filter.ingress_rules.icmp.source_cidr_block
  protocol                 = local.config.mirror_traffic_filter.ingress_rules.icmp.protocol
}

resource "aws_ec2_traffic_mirror_filter_rule" "ingress2" {
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  rule_action              = local.config.mirror_traffic_filter.ingress_rules.http.rule_action
  rule_number              = local.config.mirror_traffic_filter.ingress_rules.http.rule_number
  traffic_direction        = local.config.mirror_traffic_filter.ingress_rules.http.traffic_direction
  destination_cidr_block   = local.config.mirror_traffic_filter.ingress_rules.http.destination_cidr_block
  source_cidr_block        = local.config.mirror_traffic_filter.ingress_rules.http.source_cidr_block
  destination_port_range {
    from_port = 80
    to_port   = 80
  }

  protocol = local.config.mirror_traffic_filter.ingress_rules.http.protocol
}

resource "aws_ec2_traffic_mirror_filter_rule" "egress" {
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.filter.id
  rule_action              = local.config.mirror_traffic_filter.egress_rules.http.rule_action
  rule_number              = local.config.mirror_traffic_filter.egress_rules.http.rule_number
  traffic_direction        = local.config.mirror_traffic_filter.egress_rules.http.traffic_direction
  destination_cidr_block   = local.config.mirror_traffic_filter.egress_rules.http.destination_cidr_block
  source_cidr_block        = local.config.mirror_traffic_filter.egress_rules.http.source_cidr_block
  source_port_range {
    from_port = 80
    to_port   = 80
  }
  protocol = local.config.mirror_traffic_filter.egress_rules.http.protocol
}

resource "aws_instance" "kibana" {
  ami             = "ami-0a5dee832fbf4efed"
  instance_type   = "t2.small"
  key_name        = "20250207-ed25519"
  subnet_id       = module.vpc.public_subnet_ids[0]
  private_ip      = "10.2.0.8"
  security_groups = [for name in ["icmp", "default_out", "remote", "web", "elk"] : module.security_group.sg_ids[name]]
  tags = {
    Name = "kibana"
  }

  user_data = <<-EOT
  #!/bin/bash

  HOSTED_ZONE_ID="Z032662211JM2TEXY5ZXL"
  RECORD_NAME="kibana.f1.it-edu.org."
  TTL=60

  hostnamectl hostname kibana.f1.it-edu.org

  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600")
  INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
  PRIVATE_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/local-ipv4)
      
  sed -Ei "s/^server[.]host[:]\s+[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$/server.host: $PRIVATE_IP/i" /etc/kibana/kibana.yml
  sed -Ei "s/^elasticsearch[.]password[:]\s+["][\d\w_]*["]/elasticsearch.password: "P@ssw0rd"/i" /etc/kibana/kibana.yml
  wget https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/l/lrzsz-0.12.20-55.el9.x86_64.rpm

  cat > /tmp/route53-record.json <<EOF
  {
    "Comment": "Create A record for EC2 instance",
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "$RECORD_NAME",
          "Type": "A",
          "TTL": $TTL,
          "ResourceRecords": [
            {
              "Value": "$PRIVATE_IP"
            }
          ]
        }
      }
    ]
  }
  EOF

  aws route53 change-resource-record-sets  --hosted-zone-id "$HOSTED_ZONE_ID" --change-batch file:///tmp/route53-record.json
  cat > /var/lib/suricata/rules/suricata.rules <<EOF
  # traffic detected
  alert icmp $EXTERNAL_NET any -> $HOME_NET any (msg:"[ICMP Traffic]"; sid:2000000; gid:2000000; rev:1;)
  alert tcp $EXTERNAL_NET any -> $HOME_NET 80 (msg:"[TCP Traffic]"; sid:2000001; gid:2000000; rev:1;)
  alert udp $EXTERNAL_NET any -> $HOME_NET 80 (msg: " [UDP Traffic]"; sid:2000002; gid:2000000; rev:1;)

  # Path Traversal Attack Detection

  alert tcp   $EXTERNAL_NET any -> $HOME_NET 80 (msg: "[Path Traversal Attack1]"; content: "dvwa.f1.it-edu.org"; http_header; content: "../.."; http_uri; sid: 2000003; gid: 2000002; rev: 1;)
  alert tcp   $EXTERNAL_NET any -> $HOME_NET 80 (msg: "[Path Traversal Attack2]"; content: "dvwa.f1.it-edu.org"; http_header; pcre: "/[.]+\/[.]+/U"; classtype: successful-recon-limited; sid: 2000004; gid: 2000002; rev: 1;)

  # XSS Attack Detection

  alert tcp $EXTERNAL_NET any -> $HOME_NET 80 (msg: "[XSS Attack Detected]"; sid: 2000006; gid: 2000005; rev: 1; content: "%3Cscript%3E"; nocase; http_client_body;)

  # SQL Injection Detection

  alert tcp $EXTERNAL_NET any -> $HOME_NET 80 (msg: "[SQL injection Detect1]"; sid: 2000007; gid: 2000007; rev: 1; content: "GET"; nocase; http_method; content: "OR+1+%3D+1"; nocase; http_raw_uri;)
  alert tcp  $EXTERNAL_NET any -> $HOME_NET 80  (msg: "[SQL injection Detect2]"; sid: 2000021; gid: 2000020; rev: 1; content: "GET"; nocase; http_method; content: "%27+union+"; nocase; http_raw_uri;)
  alert tcp  $EXTERNAL_NET any -> $HOME_NET 80  (msg: "[SQL injection Detect3]"; sid: 2000022; gid: 2000020; rev: 1; content: "GET"; nocase; http_method; content: "%27+and+"; nocase; http_raw_uri;)
  EOF

  systemctl start kibana
  systemctl restart filebeat

  EOT
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
  records = [module.rds.rds]
  ttl     = 60
}
