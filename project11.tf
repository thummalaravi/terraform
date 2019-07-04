provider "aws" {
  access_key = "xxxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  region     = "us-east-2"
}

# vpc creation.
resource "aws_vpc" "project11_customised" {
  cidr_block = "10.10.0.0/16"

tags = {
    Name = "project11_customised"
  }
}
#public subnet 1a
resource "aws_subnet" "project11_public_subnet_a1" {
  vpc_id     = "${aws_vpc.project11_customised.id}"
  cidr_block = "10.10.0.0/27"
  availability_zone = "us-east-2a"

  tags = {
    Name = "project11_public_subnet_a1"
  }
}
# public subnet  b1
resource "aws_subnet" "project11_public_subnet_b1" {
  vpc_id     = "${aws_vpc.project11_customised.id}"
  cidr_block = "10.10.0.32/27"
  availability_zone = "us-east-2b"

  tags = {
    Name = "project11_public_subnet_b1"
  }
}

# public subnet  c1
resource "aws_subnet" "project11_public_subnet_c1" {
  vpc_id     = "${aws_vpc.project11_customised.id}"
  cidr_block = "10.10.0.64/27"
  availability_zone = "us-east-2c"

  tags = {
    Name = "project11_public_subnet_c1"
  }
}

# route table creation
resource "aws_route_table" "project11_rt" {
   vpc_id = "${aws_vpc.project11_customised.id}"
  
 tags = {
   Name = "project11_rt" 
   }
   
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.project11_igw.id}"
  }
}

resource "aws_internet_gateway" "project11_igw" {
  vpc_id = "${aws_vpc.project11_customised.id}"

  tags = {
    Name = "project11_igw"
  }
}

resource "aws_route_table_association" "project11_rt_ass" {
  subnet_id      = "${aws_subnet.project11_public_subnet_a1.id}"
  route_table_id = "${aws_route_table.project11_rt.id}"
}

resource "aws_route_table_association" "project11_rt_associate" {
  subnet_id      = "${aws_subnet.project11_public_subnet_b1.id}"
  route_table_id = "${aws_route_table.project11_rt.id}"
}

resource "aws_default_route_table" "project11_asso" {

  default_route_table_id = "${aws_vpc.project11_customised.default_route_table_id}"
  tags = {
  Name = "project11_asso"
  }
}

resource "aws_route_table_association" "project11_ass" {

  subnet_id      = "${aws_subnet.project11_public_subnet_c1.id}"
 route_table_id = "${aws_default_route_table.project11_asso.id}"
  
}

resource "aws_security_group" "project11_sg" {
  name = "project11_sg"
  vpc_id = "${aws_vpc.project11_customised.id}"
  ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port   = 80
      to_port     = 80
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

resource "aws_launch_configuration" "project11_conf" {
  name_prefix   = "project11-lc"
   image_id      = "ami-01384239abb7fb3b2"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  security_groups =["${aws_security_group.project11_sg.id}"]
  }

resource "aws_autoscaling_group" "project11_auto" {
   availability_zones = ["us-east-2a"]
   name = "project11_auto"
  launch_configuration = "${aws_launch_configuration.project11_conf.name}"
  vpc_zone_identifier  = ["${aws_subnet.project11_public_subnet_a1.id}"]
     desired_capacity   = 2
  max_size           =4
  min_size           = 1
 tag {
      key                 = "project11"
      value               = "newproject11"
      propagate_at_launch = true
    }
  
  }

resource "aws_elb" "project11_elb"{
  name = "project11-elb"
  subnets = ["${aws_subnet.project11_public_subnet_a1.id}", "${aws_subnet.project11_public_subnet_b1.id}"]
  security_groups =["${aws_security_group.project11_sg.id}"]
  listener{ 
instance_port = 80
  instance_protocol = "http"
  lb_port = 80
  lb_protocol ="http"
 }
 cross_zone_load_balancing = true
}


resource "aws_autoscaling_attachment" "project11_att" {
  autoscaling_group_name = "${aws_autoscaling_group.project11_auto.id}"
  elb                  = "${aws_elb.project11_elb.id}"
}

# route 53
resource "aws_route53_zone" "raviproject2" {
  name = "raviproject2.tk"
}

resource "aws_route53_record" "raviproject2" {
  zone_id = "${aws_route53_zone.raviproject2.zone_id}"
  name    = "project11.raviproject2.tk"
  type    = "A"

  alias {
    name                   = "${aws_elb.project11_elb.dns_name}"
    zone_id                = "${aws_elb.project11_elb.zone_id}"
    evaluate_target_health = true
  }
}
