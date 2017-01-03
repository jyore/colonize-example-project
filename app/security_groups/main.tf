
resource "aws_security_group" "database_sg" {
  name   = "database-${var.environment}-sg"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  tags = {
    Name = "database-${var.environment}-sg"
  }
}

resource "aws_security_group" "application_sg" {
  name   = "application-${var.environment}-sg"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  tags = {
    Name = "application-${var.environment}-sg"
  }
}

resource "aws_security_group" "lb_sg" {
  name   = "lb-${var.environment}-sg"
  vpc_id = "${data.terraform_remote_state.vpc.vpc_id}"

  tags = {
    Name = "lb-${var.environment}-sg"
  }
}

output "security_group_names" { value = "${aws_security_group.database_sg.name},${aws_security_group.application_sg.name},${aws_security_group.lb_sg.name}" }
output "security_group_ids"   { value = "${aws_security_group.database_sg.id},${aws_security_group.application_sg.id},${aws_security_group.lb_sg.id}" }
