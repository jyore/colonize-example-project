#!/bin/bash
terraform remote config \
  -backend=s3 \
  -backend-config="region=${var.region}" \
  -backend-config="bucket=terraform-states-${var.vpc_env}" \
  -backend-config="key=${var.environment}/${var.tmpl_path_dashed}_${var.environment}.tfstate"
