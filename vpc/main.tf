
resource "aws_s3_bucket" "state-bucket" {
  bucket = "terraform-states-${var.vpc_env}"

  tags {
    Name        = "Terraform Remote State Bucket"
    Environment = "${var.vpc_env}"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags {
    Name        = "application-vpc-${var.vpc_env}"
    Environment = "${var.vpc_env}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

module "subnets" {
  source = "github.com/jyore/terraform_modules//subnet"

  vpc_id  = "${aws_vpc.vpc.id}"
  region  = "${var.region}"
  zones   = "${var.availability_zones}"
  subnets = "${var.subnets}"
}


output "vpc_id" { value = "${aws_vpc.vpc.id}" }
output "subnet_ids" { value = "${module.subnets.subnet_ids}" }
output "subnet_tag_names" { value = "${module.subnets.tag_names}" }
