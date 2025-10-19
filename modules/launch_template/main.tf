/* # Launch Template 생성
resource "aws_launch_template" "example" {
  count = 3

  name_prefix = var.launch_template[count.index].name_prefix
  description = var.launch_template[count.index].description

  # AMI ID 지정
  image_id = var.launch_template[count.index].image_id

  # 인스턴스 타입
  instance_type = var.launch_template[count.index].instance_type

  # 키 페어
  key_name = var.launch_template[count.index].key_name

  # 사용자 데이터 (부팅 시 실행할 스크립트)
  user_data = var.user_data

  # 네트워크 인터페이스 설정
  network_interfaces {
    associate_public_ip_address = var.launch_template[count.index].network_interfaces.associate_public_ip_address
    delete_on_termination       = var.launch_template[count.index].network_interfaces.delete_on_termination
    security_groups = [ for name in var.launch_template[count.index].sg_names : var.sg_ids[name] ]
  }
} */

/* resource "aws_launch_template" "example" {
  for_each = var.launch_template

  name_prefix   = each.value.name_prefix
  description   = each.value.description
  image_id      = each.value.image_id
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  user_data     = base64encode(each.value.user_data)
   
  block_device_mappings {
    device_name = "/dev/xvda"  

    ebs {
      volume_size = 10
      volume_type = "gp3"
      delete_on_termination = true
    }
  }
  iam_instance_profile {
    # name = "ec2-full_access"
    arn = "arn:aws:iam::590183794316:instance-profile/ec2-full_access"
  } 

  network_interfaces {
    associate_public_ip_address = each.value.network_interfaces.associate_public_ip_address
    delete_on_termination       = each.value.network_interfaces.delete_on_termination
    security_groups = [
      for name in each.value.sg_names : var.sg_ids[name]
    ]
  }
  tags = {
    Name = "${each.key}"
  }
} */

resource "aws_launch_template" "example" {
  for_each = var.launch_template

  name_prefix   = each.value.name_prefix
  description   = each.value.description
  image_id      = each.value.image_id
  instance_type = each.value.instance_type
  key_name      = each.value.key_name
  user_data     = base64encode(each.value.user_data)

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 10
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }
  iam_instance_profile {
    # name = "ec2-full_access"
    arn = "arn:aws:iam::590183794316:instance-profile/ec2-full_access"
  }

  network_interfaces {
    associate_public_ip_address = each.value.network_interfaces.associate_public_ip_address
    delete_on_termination       = each.value.network_interfaces.delete_on_termination
    security_groups = [
      for name in each.value.sg_names : var.sg_ids[name]
    ]
  }
  tags = {
    Name = "${each.key}"
  }
}