#!/bin/bash

# Remove generated key if exist
if [ -f "tf-db-key.pem" ] ; then
       rm -f "tf-db-key.pem"
fi      
if [ -f "tf-webapp-key.pem" ] ; then
       rm -f "tf-webapp-key.pe"
fi

# Configure AWS profile
aws configure --profile tech_test


