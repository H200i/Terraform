
provider "aws" {
  region     = "us-east-1"
  access_key = "AKIARL3KQGVIGEA7E4PP"
  secret_key = "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"
}


module "ec2_module"{

  source=".//ec2_module"
}

/*
module "autoscaling"{

  source=".//autoscaling"
}


module "loadbalancer"{

  source=".//loadbalancer"
}

*/
























/*
locals {
   ingress_rules = [{
      port        = 443
      description = "Ingress rules for port 443"
   },
   {
      port        = 80
      description = "Ingree rules for port 80"
   }]
}


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_security_group" "ee" {
   name   = "resource_with_dynamic_block"
   vpc_id = aws_vpc.my_vpc.id

   dynamic "ingress" {
      for_each = local.ingress_rules

      content {
         description = ingress.value.description
         from_port   = ingress.value.port
         to_port     = ingress.value.port
         protocol    = "tcp"
         cidr_blocks = ["0.0.0.0/0"]
      }
   }

   tags = {
      Name = "AWS security group dynamic block"
   }
}
*/


/*
output "current_users" {
  value= [ for name in var.iam_users_list : name ]
}
*/
/*
resource "aws_iam_user" "iam" {
 count= length(var.iam_users_list)
 name= var.iam_users_list[count.index]  
}
*/
/*

resource "aws_iam_user" "iam" {
 for_each = var.iam_users_list
 name= each.value
}
*/





