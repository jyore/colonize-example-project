
data "terraform_remote_state" "security_groups" {
  backend = "s3"
  config {
    region = "${var.region}"
    bucket = "terraform-states-${var.vpc_env}"
    key    = "${var.environment}/security_groups_${var.environment}.tfstate"
  }
}
