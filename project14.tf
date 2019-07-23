
provider "aws" {
  access_key = "xxxxxxxxxxxxxxxxxxxxxxx"
  secret_key = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  region     = "us-east-2"
}

# vpc creation.
resource "aws_vpc" "project14_customised" {
  cidr_block = "10.10.0.0/16"

tags = {
    Name = "project14_customised"
  }
}

#public subnet a1
resource "aws_subnet" "project14_public_subnet_a1" {
  vpc_id     = "${aws_vpc.project14_customised.id}"
  cidr_block = "10.10.0.0/27"
  availability_zone = "us-east-2a"

  tags = {
    Name = "project14_public_subnet_a1"
  }
}
# public subnet  b1
resource "aws_subnet" "project14_public_subnet_b1" {
  vpc_id     = "${aws_vpc.project14_customised.id}"
  cidr_block = "10.10.0.32/27"
  availability_zone = "us-east-2b"

  tags = {
    Name = "project14_public_subnet_b1"
  }
}

# public subnet  c1
resource "aws_subnet" "project14_public_subnet_c1" {
  vpc_id     = "${aws_vpc.project14_customised.id}"
  cidr_block = "10.10.0.64/27"
  availability_zone = "us-east-2c"

  tags = {
    Name = "project14_public_subnet_c1"
  }
}

#pvt subnet a2
resource "aws_subnet" "project14_pvt_subnet_a2" {
  vpc_id     = "${aws_vpc.project14_customised.id}"
  cidr_block = "10.10.0.96/27"
  availability_zone = "us-east-2a"

  tags = {
    Name = "project14_pvt_subnet_a2"
  }
}

# pvt subnet  b2
resource "aws_subnet" "project14_pvt_subnet_b2" {
  vpc_id     = "${aws_vpc.project14_customised.id}"
  cidr_block = "10.10.0.128/27"
  availability_zone = "us-east-2b"

  tags = {
    Name = "project14_pvt_subnet_b2"
  }
}

# pvt subnet  c2
resource "aws_subnet" "project14_pvt_subnet_c2" {
  vpc_id     = "${aws_vpc.project14_customised.id}"
  cidr_block = "10.10.0.160/27"
  availability_zone = "us-east-2c"

  tags = {
    Name = "project14_pvt_subnet_c2"
  }
}

resource "aws_default_route_table" "project14_rt" {

  default_route_table_id = "${aws_vpc.project14_customised.default_route_table_id}"
  tags = {
  Name = "project14_rt"
  }
route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.project14_igw.id}"
  }
}

resource "aws_route_table" "project14_rt_pvt" {
   vpc_id = "${aws_vpc.project14_customised.id}"
  
 tags = {
   Name = "project14_rt_pvt" 
   }
   
    route {
    cidr_block = "0.0.0.0/0"
     gateway_id = "${aws_nat_gateway.project14_nat.id}"
  }
}



resource "aws_internet_gateway" "project14_igw" {
  vpc_id = "${aws_vpc.project14_customised.id}"

  tags = {
    Name = "project14_igw"
  }
}
# nat gateway
resource "aws_eip" "project14_nat_eip" {
 vpc = true
}
resource "aws_nat_gateway" "project14_nat"{
  subnet_id   = "${aws_subnet.project14_public_subnet_a1.id}"
  depends_on = ["aws_eip.project14_nat_eip"]
  allocation_id = "${aws_eip.project14_nat_eip.id}"
  tags = {d
   Name =  "project14_nat"
 }
}

# public route table association
resource "aws_route_table_association" "project14_rt_ass_1a" {

  subnet_id      = "${aws_subnet.project14_public_subnet_a1.id}"
 route_table_id = "${aws_default_route_table.project14_rt.id}"
  
}

resource "aws_route_table_association" "project14_rt_ass_1b" {

  subnet_id      = "${aws_subnet.project14_public_subnet_b1.id}"
 route_table_id = "${aws_default_route_table.project14_rt.id}"
  
}

resource "aws_route_table_association" "project14_rt_ass_1c" {

  subnet_id      = "${aws_subnet.project14_public_subnet_c1.id}"
 route_table_id = "${aws_default_route_table.project14_rt.id}"
  
}

# pvt routetable association 
resource "aws_route_table_association" "project14_rt_ass_2a" {

  subnet_id      = "${aws_subnet.project14_pvt_subnet_a2.id}"
 route_table_id = "${aws_route_table.project14_rt_pvt.id}"
  
}

resource "aws_route_table_association" "project14_rt_ass_2b" {

  subnet_id      = "${aws_subnet.project14_pvt_subnet_b2.id}"
 route_table_id = "${aws_route_table.project14_rt_pvt.id}"
  
}

resource "aws_route_table_association" "project14_rt_ass_c2" {

  subnet_id      = "${aws_subnet.project14_pvt_subnet_c2.id}"
 route_table_id = "${aws_route_table.project14_rt_pvt.id}"
  
}

resource "aws_security_group" "project14_sg" {
  name = "project14_sg"
  vpc_id = "${aws_vpc.project14_customised.id}"
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
resource "aws_launch_configuration" "project14_conf" {
  name_prefix   = "project14-lc"
  image_id                    = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  security_groups =["${aws_security_group.project14_sg.id}"]
}

resource "aws_autoscaling_group" "project14_auto" {
   availability_zones = ["us-east-2a"]
   name = "project14_auto"
  launch_configuration = "${aws_launch_configuration.project14_conf.name}"
  vpc_zone_identifier  = ["${aws_subnet.project14_pvt_subnet_a2.id}","${aws_subnet.project14_pvt_subnet_b2.id}",
	  "${aws_subnet.project14_pvt_subnet_c2.id}" ]
     desired_capacity   = 2
  max_size           =4
  min_size           = 1
load_balancers = ["${aws_elb.project14_elb.name}"]
 tag {
      key                 = "project14"
      value               = "newproject14"
      propagate_at_launch = true
    }
  
  }

resource "aws_eip" "project14_eip" {
 vpc = true
}

resource "aws_elb" "project14_elb"{
  name = "project14-elb"
  subnets = ["${aws_subnet.project14_public_subnet_a1.id}", "${aws_subnet.project14_public_subnet_b1.id}", 
	  "${aws_subnet.project14_public_subnet_c1.id}"]
  security_groups =["${aws_security_group.project14_sg.id}"]
  listener{ 
instance_port = 80
  instance_protocol = "http"
  lb_port = 80
  lb_protocol ="http"
 }
 cross_zone_load_balancing = true
}
