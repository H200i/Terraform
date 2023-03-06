
//ec2 instances in custom vpc with load balancer and route 53


locals {
    sub = ["192.168.1.0/24", "192.168.2.0/24"]
    az=["us-east-1a", "us-east-1b"]
}

resource "aws_instance" "my_ec2" {
  count         = length(local.sub) 
  ami           = "ami-0557a15b87f6559cf"
  instance_type = var.instance_type

  key_name = "keyu"
  
  
  user_data = "${data.template_file.userdata[count.index].rendered}"
  
  tags = {
    Name = "my-machine-${count.index}"
  }
  
  
  security_groups = [aws_security_group.my_sg.id]
  subnet_id= aws_subnet.my_subnet[count.index].id
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
  count         = length(local.sub) 
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = local.sub[count.index]
  availability_zone  = local.az[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-$(local.sub[count.index])"
  }
}

resource "aws_subnet" "my_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "192.168.3.0/24"
  availability_zone  = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet2-ec2"
  }
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

//-------------------load-balancer-------//

resource "aws_lb" "my_lb" {
  name               = "mylb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_sg.id]
  subnets            = [aws_subnet.my_subnet[0].id,aws_subnet.my_subnet[1].id]
  
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

// route 53

resource "aws_route53_zone" "my_zone" {
  name     = "glowfy.co.uk"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.my_zone.id
  name    = "www.glowfy.co.uk"
  type    = "CNAME"
  ttl     = "60"
  records = [aws_lb.my_lb.dns_name]
}