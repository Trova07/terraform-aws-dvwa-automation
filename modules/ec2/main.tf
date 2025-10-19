locals {
  public_ec2s = flatten([
    for k, v in var.ec2_instances : [
      for i in range(v.count) : merge({
        for k2, v2 in v : k2 => v2
      }, { name = "${k}-${i + 1}" }) if v.public == true
    ]
  ])

  private_ec2s = flatten([
    for k, v in var.ec2_instances : [
      for i in range(v.count) : merge({
        for k2, v2 in v : k2 => v2
      }, { name = "${k}-${i + 1}" }) if v.public == false
    ]
  ])
}

resource "aws_instance" "public_ec2s" {
  count = length(local.public_ec2s)

  ami             = local.public_ec2s[count.index].ami_id
  instance_type   = local.public_ec2s[count.index].instance_type
  subnet_id       = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  security_groups = [for name in local.public_ec2s[count.index].sg_names : var.sg_ids[name]]
  key_name        = var.key_name
  tags = {
    Name = "${var.region_name}-ec2-${local.public_ec2s[count.index].name}"
  }
  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOT
#!/bin/bash

wget https://dl.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/Packages/l/lrzsz-0.12.20-55.el9.x86_64.rpm
rpm -i lrzsz-0.12.20-55.el9.x86_64.rpm

rm -f *.rpm

EOT  
}
/* resource "aws_instance" "ec2_web2" {
  ami             = var.ec2_instances.web.ami_id
  instance_type   = var.ec2_instances.web.instance_type
  key_name        = var.key_name
  subnet_id       = var.public_subnet_ids[1]
  security_groups = [for name in var.ec2_instances.web.sg_names : var.sg_ids[name]]

  tags = {
    Name = "${var.region_name}-ec2-web2"
  }
   connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.key_name)
      host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [ 
      "sudo dnf install -y httpd",
      "sudo systemctl start httpd" 
    ]
  }

  provisioner "file" {
    source = "./id_ed25519.pub" 
    destination = "/home/ec2-user/.ssh/authorized_keys" 
  }  
} 
  */
resource "aws_instance" "private_ec2s" {
  count = length(local.private_ec2s)

  ami             = local.private_ec2s[count.index].ami_id
  instance_type   = local.private_ec2s[count.index].instance_type
  subnet_id       = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  key_name        = var.key_name
  security_groups = [for name in local.private_ec2s[count.index].sg_names : var.sg_ids[name]]
  tags = {
    Name = "${var.region_name}-ec2-${local.private_ec2s[count.index].name}"
  }
  lifecycle {
    create_before_destroy = true
  }
}

/* resource "aws_route53_record" "web" {
  zone_id = "Z032662211JM2TEXY5ZXL"
  name = "www.f1.it-edu.org"
  type = "A"
  records = [ for i in range(length(aws_instance.public_ec2s)): aws_instance.public_ec2s[i].public_ip ]
  ttl = 300
}
*/
resource "aws_route53_record" "web1" {
  count   = length(aws_instance.public_ec2s)
  zone_id = "Z032662211JM2TEXY5ZXL"
  name    = "web${count.index + 1}.f1.it-edu.org"
  type    = "A"
  records = [aws_instance.public_ec2s[count.index].public_ip]
  ttl     = 300
}
