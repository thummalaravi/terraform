provider "aws" {
  access_key = "xxxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  region     = "us-east-2"
}

# vpc creation.
resource "aws_vpc" "project13_customised" {
  cidr_block = "10.10.0.0/16"

tags = {
    Name = "project13_customised"
  }
}

#public subnet a1
resource "aws_subnet" "project13_public_subnet_a1" {
  vpc_id     = "${aws_vpc.project13_customised.id}"
  cidr_block = "10.10.0.0/27"
  availability_zone = "us-east-2a"

  tags = {
    Name = "project13_public_subnet_a1"
  }
}
# public subnet  b1
resource "aws_subnet" "project13_public_subnet_b1" {
  vpc_id     = "${aws_vpc.project13_customised.id}"
  cidr_block = "10.10.0.32/27"
  availability_zone = "us-east-2b"

  tags = {
    Name = "project13_public_subnet_b1"
  }
}

# public subnet  c1
resource "aws_subnet" "project13_public_subnet_c1" {
  vpc_id     = "${aws_vpc.project13_customised.id}"
  cidr_block = "10.10.0.64/27"
  availability_zone = "us-east-2c"

  tags = {
    Name = "project13_public_subnet_c1"
  }
}

resource "aws_default_route_table" "project13_rt" {

  default_route_table_id = "${aws_vpc.project13_customised.default_route_table_id}"
  tags = {
  Name = "project13_rt"
  }
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.project13_igw.id}"
  }
}

resource "aws_route_table_association" "project13_rt_ass_1a" {

  subnet_id      = "${aws_subnet.project13_public_subnet_a1.id}"
 route_table_id = "${aws_default_route_table.project13_rt.id}"
  
}

resource "aws_route_table_association" "project13_rt_ass_1b" {

  subnet_id      = "${aws_subnet.project13_public_subnet_b1.id}"
 route_table_id = "${aws_default_route_table.project13_rt.id}"
  
}

resource "aws_route_table_association" "project13_rt_ass_1c" {

  subnet_id      = "${aws_subnet.project13_public_subnet_c1.id}"
 route_table_id = "${aws_default_route_table.project13_rt.id}"
  
}

resource "aws_internet_gateway" "project13_igw" {
  vpc_id = "${aws_vpc.project13_customised.id}"

  tags = {
    Name = "project13_igw"
  }
}

resource "aws_security_group" "project13_sg" {
  name = "project13_sg"
  vpc_id = "${aws_vpc.project13_customised.id}"
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
 ingress {
      from_port   = 8080
      to_port     = 8080
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

# launch configuration
resource "aws_launch_configuration" "project13_conf" {
  name_prefix   = "project13-lc"
   image_id      = "ami-08fba854c7827042b"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  security_groups =["${aws_security_group.project13_sg.id}"]
  }
resource "aws_autoscaling_group" "project13_auto" {
   availability_zones = ["us-east-2a"]
   name = "project13_auto"
  launch_configuration = "${aws_launch_configuration.project13_conf.name}"
  vpc_zone_identifier  = ["${aws_subnet.project13_public_subnet_a1.id}","${aws_subnet.project13_public_subnet_b1.id}","${aws_subnet.project13_public_subnet_c1.id}" ]
     desired_capacity   = 2
  max_size           =4
  min_size           = 1
load_balancers = ["${aws_elb.project13_elb.name}"]
 tag {
      key                 = "project13"
      value               = "newproject13"
      propagate_at_launch = true
    }
  
  }

resource "aws_eip" "project13_eip" {
 vpc = true
}

resource "aws_elb" "project13_elb"{
  name = "project13-elb"
  subnets = ["${aws_subnet.project13_public_subnet_a1.id}", "${aws_subnet.project13_public_subnet_b1.id}", "${aws_subnet.project13_public_subnet_c1.id}"]
  security_groups =["${aws_security_group.project13_sg.id}"]
  listener{ 
instance_port = 80
  instance_protocol = "http"
  lb_port = 80
  lb_protocol ="http"
 }
 cross_zone_load_balancing = true
}

# route 53
resource "aws_route53_zone" "raviproject2" {
	
  name = "raviproject2.tk"
}

resource "aws_route53_record" "raviproject2" {
#terraform import aws_route53_zone.raviproject2. Z264VR5H0D90T1
  zone_id = "${aws_route53_zone.raviproject2.id}"
  name    = "project13.raviproject2.tk"
  type    = "A"

  alias {
   name                   = "${aws_elb.project13_elb.dns_name}"
   zone_id                = "${aws_elb.project13_elb.zone_id}"
    evaluate_target_health = true
    }
}

resource "aws_instance" "project13_public" {
  ami           = "ami-01a3c164e506523ad" 
  instance_type = "t2.micro"
  security_groups =["${aws_security_group.project13_sg.id}"]
  subnet_id  = "${aws_subnet.project13_public_subnet_c1.id}"
  associate_public_ip_address = "true"

}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = "${aws_instance.project13_public.id}"
  allocation_id = "${aws_eip.project13_eip.id}"
}


# “terraform import aws_route53_zone.raviproject2 Z264VR5H0D90T1”
# “terraform destroy -target aws_route53_zone.raviproject2”
