provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

data "aws_availability_zones" "available" {}

resource "aws_default_vpc" "default" {}

resource "aws_default_subnet" "subnet1" {

  availability_zone = "${data.aws_availability_zones.available.names[0]}"
}
resource "aws_default_subnet" "subnet2" {
  
  availability_zone = "${data.aws_availability_zones.available.names[1]}"
}
resource "aws_default_subnet" "subnet3" {
  
  availability_zone = "${data.aws_availability_zones.available.names[2]}"
}

resource "aws_iam_role" "instance_role" {
  name               = "LoadTestRole"
  assume_role_policy = "${file("ec2-assume-role.json")}"
}

resource "aws_iam_policy_attachment" "instance_role_attach" {
  name       = "access-for-s3"
  roles      = ["${aws_iam_role.instance_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "ec2" {
  name_prefix = "load-test-instance-profile"
  path  = "/"
  role = "${aws_iam_role.instance_role.name}"
}

resource "aws_placement_group" "load_test" {
  name     = "load-test"
  strategy = "cluster"
}

resource "aws_security_group" "load-test" {
    name_prefix = "load-test"
    description = "Used in load-test"
    vpc_id = "${aws_default_vpc.default.id}"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }

    egress {
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
    }
    tags {
      Name = "load-test"
    }
}

resource "aws_launch_configuration" "load_test" {
  name_prefix   = "load-test-config"
  image_id      = "${var.load_test_ami}"
  instance_type = "${var.instance_size}"
  iam_instance_profile = "${aws_iam_instance_profile.ec2.name}"
  key_name = "${var.key_name}"
  security_groups = ["${aws_security_group.load-test.id}"]
  ebs_optimized = true
  associate_public_ip_address = true
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "load-test-group" {
  name                 = "load-test-group"
  desired_capacity     = 1
  min_size             = 1
  max_size             = 2
  placement_group      = "${aws_placement_group.load_test.id}"
  launch_configuration = "${aws_launch_configuration.load_test.name}"
  vpc_zone_identifier  = [
    "${aws_default_subnet.subnet1.id}",
    "${aws_default_subnet.subnet2.id}",
    "${aws_default_subnet.subnet3.id}"
  ]

  tag {
    key                 = "Name"
    value               = "load-test"
    propagate_at_launch = true
  }
}
