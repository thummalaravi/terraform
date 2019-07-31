data "aws_ami" "ubuntu" {

 most_recent      = true
 owners           = ["self"]

 filter {
   name   = "name"
   values = ["ansible-*"]
 }

 filter {
   name   = "virtualization-type"
   values = ["hvm"]
 }
}
