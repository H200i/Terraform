



locals {
    ips = ["192.168.1.10", "192.168.1.11"]
}

resource "aws_instance" "my_ec2" {
  count         = length(local.ips) 
  ami           = "ami-0557a15b87f6559cf"
  instance_type = var.instance_type

  key_name = "keyu"
  
  
  user_data = "${data.template_file.userdata[count.index].rendered}"
  
  tags = {
    Name = "my-machine-${count.index}"
  }
  
  network_interface {
    network_interface_id = aws_network_interface.my_ni[count.index].id
    device_index         = 0

  }
}

data "template_file" "userdata" {
count=2
template = "${file("ec2_module/apache_config.sh")}"
vars = {
   namevalue = count.index
}
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "vpc-ec2"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone  = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-ec2"
  }
}



resource "aws_network_interface" "my_ni" {
  count           = length(local.ips)
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = [local.ips[count.index]]

  tags = {
    Name = "network_interface-ec2${count.index}"
  }
  security_groups = [aws_security_group.my_sg.id]
}



resource "aws_security_group" "my_sg" {
 name        = "my_sg"
 vpc_id      = aws_vpc.my_vpc.id

ingress {
   description = "SSH access"
   from_port   = 22
   to_port     = 22
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
}
ingress {
   description = "http access"
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
 tags = {
    Name = "sg-ec2"
  }
}

resource "aws_internet_gateway" "my_gtway" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name : "my_gtway"
  }
}

resource "aws_default_route_table" "example" {
  default_route_table_id = aws_vpc.my_vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gtway.id
  }

  tags = {
    Name = "example"
  }
  
}

/*-------------------load-balancer-------//

resource "aws_lb" "my_lb" {
  name               = "mylb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_sg.id]
  // subnets            = [aws_subnet.my_subnet.id]
  
}

resource "aws_lb_listener" "my_lis" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

resource "aws_lb_target_group" "my_tg" {
  name     = "mytg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
  health_check {
    enabled             = true
    healthy_threshold   = 3
    interval            = 10
    matcher             = 200
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 3
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "attach-app1" {
  count=2
  target_group_arn = aws_lb_target_group.my_tg.arn
  target_id        = aws_instance.my_ec2[count.index].id
  port             = 80
}
*/