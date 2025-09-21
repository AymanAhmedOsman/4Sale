 terraform {
   backend "s3" {
     bucket = "demotf12"
     key    = "terraform.tfstate"
     region = "eu-west-1"   
   }
 }


