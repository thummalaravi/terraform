provider "aws" {
  access_key = "xxxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  region     = "us-east-2"
}

# vpc creation.
resource "aws_vpc" "ravi_customised" {
  cidr_block = "10.10.0.0/16"

tags = {
    Name = "ravi_customised"
  }
}
#public subnet 1a
resource "aws_subnet" "Public_subnet_a1" {
  vpc_id     = "${aws_vpc.ravi_customised.id}"
  cidr_block = "10.10.0.0/27"
  availability_zone = "us-east-2a"

  tags = {
    Name = "Public_subnet_a1"
  }
}
# public subnet  b1
resource "aws_subnet" "Public_subnet_b1" {
  vpc_id     = "${aws_vpc.ravi_customised.id}"
  cidr_block = "10.10.0.32/27"
  availability_zone = "us-east-2b"

  tags = {
    Name = "Public_subnet_b1"
  }
}

# pvt subnet b2
resource "aws_subnet" "pvt_subnet_b2" {
  vpc_id     = "${aws_vpc.ravi_customised.id}"
  cidr_block = "10.10.0.64/27"
  availability_zone = "us-east-2b"

  tags = {
    Name = "pvt_subnet_b2"
  }
}
# route table creation
resource "aws_route_table" "rt_public" {
   vpc_id = "${aws_vpc.ravi_customised.id}"
  
 tags = {
   Name = "rt_public" 
   }
   
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ravi_igw.id}"
  }
}

resource "aws_internet_gateway" "ravi_igw" {
  vpc_id = "${aws_vpc.ravi_customised.id}"

  tags = {
    Name = "ravi_igw"
  }
}

resource "aws_eip" "nat" {
 vpc = true
}

resource "aws_nat_gateway" "ravi_nat"{
  subnet_id   = "${aws_subnet.Public_subnet_a1.id}"
  depends_on = ["aws_eip.nat"]
  allocation_id = "${aws_eip.nat.id}"
  tags = {
   Name =  "ravi_nat"
 }
}

resource "aws_route_table_association" "rt_public_ass" {
  subnet_id      = "${aws_subnet.Public_subnet_a1.id}"
  route_table_id = "${aws_route_table.rt_public.id}"
}

resource "aws_default_route_table" "pvt_asso" {

  default_route_table_id = "${aws_vpc.ravi_customised.default_route_table_id}"
  tags = {
  Name = "pvt_rt_ass"
  }
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ravi_nat.id}"
  }
}

resource "aws_route_table_association" "rt_pvt_ass" {

  subnet_id      = "${aws_subnet.pvt_subnet_b2.id}"
 route_table_id = "${aws_default_route_table.pvt_asso.id}"
  
}
resource "aws_security_group" "ravi_sg" {
  name = "ravi_sg"
  vpc_id = "${aws_vpc.ravi_customised.id}"
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

resource "aws_launch_configuration" "as_conf" {
  name_prefix   = "terraform-lc"
   image_id      = "ami-01384239abb7fb3b2"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  security_groups =["${aws_security_group.ravi_sg.id}"]
}

resource "aws_autoscaling_group" "ravi_auto" {
   availability_zones = ["us-east-2a"]
  launch_configuration = "${aws_launch_configuration.as_conf.name}"
  vpc_zone_identifier  = ["${aws_subnet.Public_subnet_a1.id}"]
     desired_capacity   = 2
  max_size           =4
  min_size           = 1
}

resource "aws_elb" "ravi_elb"{
  name = "ravi-elb"
  subnets = ["${aws_subnet.Public_subnet_a1.id}", "${aws_subnet.Public_subnet_b1.id}"]
  security_groups =["${aws_security_group.ravi_sg.id}"]
  listener{ 
instance_port = 80
  instance_protocol = "http"
  lb_port = 80
  lb_protocol ="http"
 }
 cross_zone_load_balancing = true
}


resource "aws_autoscaling_attachment" "ravi_att" {
  autoscaling_group_name = "${aws_autoscaling_group.ravi_auto.id}"
  elb                  = "${aws_elb.ravi_elb.id}"
}

# route 53
resource "aws_route53_zone" "raviproject2" {
  name = "raviproject2.tk"
}

resource "aws_route53_record" "raviproject2" {
  zone_id = "${aws_route53_zone.raviproject2.zone_id}"
  name    = "raviproject2.tk"
  type    = "A"

  alias {
    name                   = "${aws_elb.ravi_elb.dns_name}"
    zone_id                = "${aws_elb.ravi_elb.zone_id}"
    evaluate_target_health = true
  }
}
