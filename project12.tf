provider "aws" {
  access_key = "xxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  region     = "us-east-2"
}
# vpc creation.
resource "aws_vpc" "project12_customised" {
  cidr_block = "10.10.0.0/16"

tags = {
    Name = "project12_customised"
  }
}
#public subnet 1a
resource "aws_subnet" "project12_public_subnet_a1" {
  vpc_id     = "${aws_vpc.project12_customised.id}"
  cidr_block = "10.10.0.0/27"
  availability_zone = "us-east-2a"

  tags = {
    Name = "project12_public_subnet_a1"
  }
}

# pvt subnet a2
resource "aws_subnet" "project12_pvt_subnet_a2" {
  vpc_id     = "${aws_vpc.project12_customised.id}"
  cidr_block = "10.10.0.32/27"
  availability_zone = "us-east-2a"

  tags = {
    Name = "project12_pvt_subnet_a2"
  }
}

# public subnet  b1
resource "aws_subnet" "project12_public_subnet_b1" {
  vpc_id     = "${aws_vpc.project12_customised.id}"
  cidr_block = "10.10.0.64/27"
  availability_zone = "us-east-2b"

  tags = {
    Name = "project12_Public_subnet_b1"
  }
}





resource "aws_route_table" "project12_rt_public" {
   vpc_id = "${aws_vpc.project12_customised.id}"
  
 tags = {
   Name = "project12_rt_public" 
   }
   
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.project12_igw.id}"
  }
}

resource "aws_internet_gateway" "project12_igw" {
  vpc_id = "${aws_vpc.project12_customised.id}"

  tags = {
    Name = "project12_igw"
  }
}

resource "aws_eip" "project12_nat_eip" {
 vpc = true
}

resource "aws_nat_gateway" "project12_nat"{
  subnet_id   = "${aws_subnet.project12_public_subnet_a1.id}"
  depends_on = ["aws_eip.project12_nat_eip"]
  allocation_id = "${aws_eip.project12_nat_eip.id}"
  tags = {
   Name =  "project12_nat"
 }
}


resource "aws_route_table_association" "project12_rt_public_ass" {
  subnet_id      = "${aws_subnet.project12_public_subnet_a1.id}"
  route_table_id = "${aws_route_table.project12_rt_public.id}"
}

resource "aws_route_table_association" "project12_rt_public_assaction" {
  subnet_id      = "${aws_subnet.project12_public_subnet_b1.id}"
  route_table_id = "${aws_route_table.project12_rt_public.id}"
}

resource "aws_default_route_table" "project12_pvt_asso" {

  default_route_table_id = "${aws_vpc.project12_customised.default_route_table_id}"
  tags = {
  Name = "pvt_rt_ass"
  }
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.project12_nat.id}"
  }
}

resource "aws_route_table_association" "project12_rt_pvt_ass" {

  subnet_id = "${aws_subnet.project12_pvt_subnet_a2.id}"
 route_table_id = "${aws_default_route_table.project12_pvt_asso.id}"
  
}

resource "aws_security_group" "project12_sg" {
  name = "project12_sg"
  vpc_id = "${aws_vpc.project12_customised.id}"
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
}

resource "aws_launch_configuration" "project12_conf" {
  name_prefix   = "project12-lc"
   image_id      = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  security_groups =["${aws_security_group.project12_sg.id}"]
}

resource "aws_autoscaling_group" "project12_auto" {
   availability_zones = ["us-east-2"]
  launch_configuration = "${aws_launch_configuration.project12_conf.name}"
  name = "project12_asg"
  vpc_zone_identifier  = ["${aws_subnet.project12_pvt_subnet_a2.id}"]
  
   desired_capacity   = 1
  max_size           =4
  min_size           = 1
  tag {
      key                 = "project12"
      value               = "newproject12"
      propagate_at_launch = true
    }
  
}

resource "aws_elb" "project12_elb"{
  name = "project12-elb"
  subnets = ["${aws_subnet.project12_public_subnet_a1.id}", "${aws_subnet.project12_public_subnet_b1.id}"]
  security_groups =["${aws_security_group.project12_sg.id}"]
  listener{ 
instance_port = 80
  instance_protocol = "http"
  lb_port = 80
  lb_protocol ="http"
 }
 cross_zone_load_balancing = true
}
resource "aws_autoscaling_attachment" "project12_att" {
  autoscaling_group_name = "${aws_autoscaling_group.project12_auto.id}"
  elb                  = "${aws_elb.project12_elb.id}"
}
# route 53
resource "aws_route53_zone" "raviproject2" {
  name = "raviproject2.tk"
}

resource "aws_route53_record" "raviproject2" {
  zone_id = "${aws_route53_zone.raviproject2.zone_id}"
  name    = "project12.raviproject2.tk"
  type    = "A"

  alias {
    name                   = "${aws_elb.project12_elb.dns_name}"
    zone_id                = "${aws_elb.project12_elb.zone_id}"
    evaluate_target_health = true
  }
}



  
