
module "db_subnets" {
  source = "github.com/jyore/terraform_modules//multi_key_lookup"

  keys           = "${var.vpc_env}-database-az1,${var.vpc_env}-database-az2"
  map_key_list   = "${data.terraform_remote_state.vpc.subnet_tag_names}"
  map_value_list = "${data.terraform_remote_state.vpc.subnet_ids}"
}

module "db_security_groups" {
  source = "github.com/jyore/terraform_modules//multi_key_lookup"

  keys           = "database-${var.environment}-sg"
  map_key_list   = "${data.terraform_remote_state.security_groups.security_group_names}"
  map_value_list = "${data.terraform_remote_state.security_groups.security_group_ids}"
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = ["${compact(split(",",module.db_subnets.values))}"]

  tags {
    Name        = "${var.environment}-db-subnet-group"
  }
}

resource "aws_rds_cluster" "application_database_cluster" {
  cluster_identifier     = "application-${var.environment}-database-cluster"
  db_subnet_group_name   = "${aws_db_subnet_group.db_subnet_group.name}"
  vpc_security_group_ids = ["${compact(split(",",module.db_security_groups.values))}"]
  database_name          = "applicationdb"
  master_username        = "admin"
  master_password        = "password"
}

resource "aws_rds_cluster_instance" "application_database_cluster_instance" {
  count = 2

  identifier           = "application-${var.environment}-database-${count.index}"
  db_subnet_group_name = "${aws_db_subnet_group.db_subnet_group.name}"
  cluster_identifier   = "${aws_rds_cluster.application_database_cluster.id}"
  instance_class       = "${var.database_instance_size}"
}
