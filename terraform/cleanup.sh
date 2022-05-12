#!/bin/bash

# Remove terraform cache
terraform destroy -auto-approve
rm -rf terraform.tfstate*
rm -rf .terraform*
rm -f tf-db-key.pem
rm -f tf-webapp-key.pem 
