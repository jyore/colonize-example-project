# Variables
# -------------------------------------------------------------------------------
variable "user_data" { default = <<EOF
#!/bin/bash

sudo yum update -y
sudo yum install -y httpd
sudo service httpd start
EOF
}


# Internal Map Lookups
# -------------------------------------------------------------------------------
module "app_subnets" {
  source = "github.com/jyore/terraform_modules//multi_key_lookup"

  keys           = "${var.vpc_env}-application-az1,${var.vpc_env}-application-az2"
  map_key_list   = "${data.terraform_remote_state.vpc.subnet_tag_names}"
  map_value_list = "${data.terraform_remote_state.vpc.subnet_ids}"
}

module "lb_sg" {
  source = "github.com/jyore/terraform_modules//multi_key_lookup"

  keys           = "lb-${var.environment}-sg"
  map_key_list   = "${data.terraform_remote_state.security_groups.security_group_names}"
  map_value_list = "${data.terraform_remote_state.security_groups.security_group_ids}"
}

module "app_sg" {
  source = "github.com/jyore/terraform_modules//multi_key_lookup"

  keys           = "application-${var.environment}-sg"
  map_key_list   = "${data.terraform_remote_state.security_groups.security_group_names}"
  map_value_list = "${data.terraform_remote_state.security_groups.security_group_ids}"
}


# Resources
# -------------------------------------------------------------------------------

resource "aws_elb" "lb" {
  name            = "application-${var.environment}-elb"
  subnets         = ["${compact(split(",",module.app_subnets.values))}"]
  security_groups = ["${compact(split(",",module.lb_sg.values))}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  tags {
    Name        = "application-${var.environment}-elb"
    Environment = "${var.environment}"
  }
}

resource "aws_launch_configuration" "asg_launch_config" {
  name              = "application-${var.environment}-launch-config"
  image_id          = "${lookup(var.ami_by_region, var.region)}"
  instance_type     = "${var.application_instance_size}"
  security_groups   = ["${compact(split(",",module.app_sg.values))}"]
  user_data         = "${var.user_data}"
  enable_monitoring = true
  
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 10
    delete_on_termination = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "application-${var.environment}-asg"
  launch_configuration      = "${aws_launch_configuration.asg_launch_config.name}"
  min_size                  = "${var.asg_min_size}"
  max_size                  = "${var.asg_max_size}"
  desired_capacity          = "${var.asg_desired_capacity}"
  load_balancers            = ["${aws_elb.lb.name}"]
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier       = ["${compact(split(",",module.app_subnets.values))}"]
  enabled_metrics           = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  tag {
    key                 = "Environment"
    value               = "${var.environment}"
    propagate_at_launch = true
  }
}
