resource "aws_launch_configuration" "project16_conf" {
  name_prefix          =  "project16_conf"
  image_id             =  "${data.aws_ami.ubuntu.id}"
  instance_type        =  "t2.micro"
  key_name             =  "master"
  security_groups      = ["${aws_security_group.project16_sg.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "project16_autoscaling" {
  name                 = "${aws_launch_configuration.project16_conf.name}-asg"
  vpc_zone_identifier  = ["${aws_subnet.project16_pvt_subnet_a2.id}"]
  launch_configuration = "${aws_launch_configuration.project16_conf.name}"
  min_size             = 1
  max_size             = 2
  health_check_grace_period = 300
  health_check_type = "EC2"
  force_delete = true

  lifecycle {
    create_before_destroy = true
  }

  tag {
      key = "Name"
      value = "ec2 instance"
      propagate_at_launch = true
   }
}

# creating elastic ip
resource "aws_eip" "project16_eip" {
  vpc = true
}

# creating elastic load balancer
resource "aws_elb" "project16_elb"{
  name = "project16-elb"
  subnets = ["${aws_subnet.project16_public_subnet_a1.id}"]
  security_groups =["${aws_security_group.project16_sg.id}"]
  listener{
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol ="http"
  }
  cross_zone_load_balancing = true
}

# load balancer attach to autoscaling group
resource "aws_autoscaling_attachment" "project16_attach" {
   autoscaling_group_name = "${aws_autoscaling_group.project16_autoscaling.id}"
   elb                  = "${aws_elb.project16_elb.id}"
}

# route 53
resource "aws_route53_zone" "raviproject2" {
	
  name = "raviproject2.tk"
}

resource "aws_route53_record" "raviproject2" {
#terraform import aws_route53_zone.raviproject2. Z264VR5H0D90T1
  zone_id = "${aws_route53_zone.raviproject2.id}"
  name    = "project16.raviproject2.tk"
  type    = "A"

  alias {
   name                   = "${aws_elb.project16_elb.dns_name}"
   zone_id                = "${aws_elb.project16_elb.zone_id}"
    evaluate_target_health = true
    }
}
