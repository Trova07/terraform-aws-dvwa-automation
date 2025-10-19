resource "aws_autoscaling_group" "gnuboard" {
  count                     = contains(keys(var.autoscaling_group), "gnuboard") && var.id_gnuboard != null ? 1 : 0
  name                      = var.autoscaling_group["gnuboard"].name
  desired_capacity          = var.autoscaling_group["gnuboard"].desired_capacity
  min_size                  = var.autoscaling_group["gnuboard"].min_size
  max_size                  = var.autoscaling_group["gnuboard"].max_size
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = var.autoscaling_group["gnuboard"].health_check_type
  health_check_grace_period = var.autoscaling_group["gnuboard"].health_check_grace_period
  launch_template {
    id      = var.id_gnuboard
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = var.autoscaling_group["gnuboard"].name
    propagate_at_launch = true
  }
  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 100
  }
}

resource "aws_autoscaling_group" "dvwa-filebeat" {
  count                     = contains(keys(var.autoscaling_group), "dvwa-filebeat") && var.id_dvwa != null ? 1 : 0
  name                      = var.autoscaling_group["dvwa-filebeat"].name
  desired_capacity          = var.autoscaling_group["dvwa-filebeat"].desired_capacity
  min_size                  = var.autoscaling_group["dvwa-filebeat"].min_size
  max_size                  = var.autoscaling_group["dvwa-filebeat"].max_size
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = var.autoscaling_group["dvwa-filebeat"].health_check_type
  health_check_grace_period = var.autoscaling_group["dvwa-filebeat"].health_check_grace_period
  launch_template {
    id      = var.id_dvwa
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = var.autoscaling_group["dvwa-filebeat"].name
    propagate_at_launch = true
  }
  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 100
  }
}

resource "aws_autoscaling_group" "elasticsearch1" {
  count                     = contains(keys(var.autoscaling_group), "elasticsearch1") && var.id_elasticsearch1 != null ? 1 : 0
  name                      = var.autoscaling_group["elasticsearch1"].name
  desired_capacity          = var.autoscaling_group["elasticsearch1"].desired_capacity
  min_size                  = var.autoscaling_group["elasticsearch1"].min_size
  max_size                  = var.autoscaling_group["elasticsearch1"].max_size
  vpc_zone_identifier       = ["${var.public_subnet_ids[0]}"]
  health_check_type         = var.autoscaling_group["elasticsearch1"].health_check_type
  health_check_grace_period = var.autoscaling_group["elasticsearch1"].health_check_grace_period
  launch_template {
    id      = var.id_elasticsearch1
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = var.autoscaling_group["elasticsearch1"].name
    propagate_at_launch = true
  }
  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 100
  }
}

resource "aws_autoscaling_group" "elasticsearch2" {
  count                     = contains(keys(var.autoscaling_group), "elasticsearch2") && var.id_elasticsearch2 != null ? 1 : 0
  name                      = var.autoscaling_group["elasticsearch2"].name
  desired_capacity          = var.autoscaling_group["elasticsearch2"].desired_capacity
  min_size                  = var.autoscaling_group["elasticsearch2"].min_size
  max_size                  = var.autoscaling_group["elasticsearch2"].max_size
  vpc_zone_identifier       = ["${var.public_subnet_ids[1]}"]
  health_check_type         = var.autoscaling_group["elasticsearch2"].health_check_type
  health_check_grace_period = var.autoscaling_group["elasticsearch2"].health_check_grace_period
  launch_template {
    id      = var.id_elasticsearch2
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = var.autoscaling_group["elasticsearch2"].name
    propagate_at_launch = true
  }
  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 100
  }
}

resource "aws_autoscaling_policy" "cpu_util1" {
  count                  = length(aws_autoscaling_group.gnuboard) > 0 ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.gnuboard[0].name
  name                   = var.autoscaling_policy.name

  policy_type = var.autoscaling_policy.policy_type
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.autoscaling_policy.predefined_metric_type
    }
    target_value = var.autoscaling_policy.target_value
  }
  estimated_instance_warmup = var.autoscaling_policy.estimated_instance_warmup
}

resource "aws_autoscaling_policy" "cpu_util2" {
  count                  = length(aws_autoscaling_group.dvwa-filebeat) > 0 ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.dvwa-filebeat[0].name
  name                   = var.autoscaling_policy.name

  policy_type = var.autoscaling_policy.policy_type
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.autoscaling_policy.predefined_metric_type
    }
    target_value = var.autoscaling_policy.target_value
  }
  estimated_instance_warmup = var.autoscaling_policy.estimated_instance_warmup
}

resource "aws_autoscaling_policy" "cpu_util3" {
  count                  = length(aws_autoscaling_group.elasticsearch1) > 0 ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.elasticsearch1[0].name
  name                   = var.autoscaling_policy.name

  policy_type = var.autoscaling_policy.policy_type
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.autoscaling_policy.predefined_metric_type
    }
    target_value = var.autoscaling_policy.target_value
  }
  estimated_instance_warmup = var.autoscaling_policy.estimated_instance_warmup
}

resource "aws_autoscaling_policy" "cpu_util4" {
  count                  = length(aws_autoscaling_group.elasticsearch2) > 0 ? 1 : 0
  autoscaling_group_name = aws_autoscaling_group.elasticsearch2[0].name
  name                   = var.autoscaling_policy.name

  policy_type = var.autoscaling_policy.policy_type
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = var.autoscaling_policy.predefined_metric_type
    }
    target_value = var.autoscaling_policy.target_value
  }
  estimated_instance_warmup = var.autoscaling_policy.estimated_instance_warmup
}  