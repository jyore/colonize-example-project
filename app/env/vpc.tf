
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    region = "${var.region}"
    bucket = "terraform-states-${var.vpc_env}"
    key    = "${var.vpc_env}/vpc_${var.vpc_env}.tfstate"
  }
}
