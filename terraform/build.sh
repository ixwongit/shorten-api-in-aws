#!/bin/bash

# Terraform 
terraform init
terraform plan -out terraform.out
terraform apply -auto-approve terraform.out

if [ -f "terraform.out" ] ; then
	rm "terraform.out"
fi
