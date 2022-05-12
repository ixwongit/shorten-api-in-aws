# shorten-api-in-aws
Testing system deployment on AWS using free tier. 

### Background
Design diagram:

[diagram](./design_diagram.jpg) 

There are 2 directories:
- ./terraform : Actual deploy script
- ./webapp : Webapp source code (I have built it and push the container to Dockerhub. Only terraform deployment script for test.)

### Environment Setup
Please feel free to use my personal AWS access key to test the script or use your own access key.
Please ensure aws-cli has been installed.

The AWS user should have the below policy for ./setup_env.sh
- ElasticLoadBalancingFullAccess
- AmazonVPCFullAccess
- AmazonS3FullAccess
- AmazonEC2FullAccess

~/.aws/config   (There is a setting for profile name tech_test)
```
[profile tech_test]
region = ap-southeast-1
output = json
```

<mark>Important</mark>

Please ensure 10.0.0.0/16 is not used for VPC CIDR.

### [setup_env.sh](./terraform/setup_env.sh)
This script is to setup AWS profile.
```
cd ./terraform
chmod +x setup_env.sh
./setup_env.sh
```
Example. Please input the access key and secret key. We use ap-southeast-1 region for the testing.
```
[ec2-user@ip-172-31-19-20 test03]$ cd terraform/
[ec2-user@ip-172-31-19-20 terraform]$ chmod +x setup_env.sh 
[ec2-user@ip-172-31-19-20 terraform]$ ./setup_env.sh 
AWS Access Key ID [****************V3DT]: 
AWS Secret Access Key [****************y/+6]: 
Default region name [ap-southeast-1]: 
Default output format [json]: 

```
### Usage of [build.sh](./terraform/build.sh)
Ensure profile tech_test is configured
```
cd ./terraform
chmod +x build.sh
./build.sh
```

### Test Result
```
[ec2-user@ip-172-31-19-20 test03]$ cd terraform/
[ec2-user@ip-172-31-19-20 terraform]$ chmod +x build.sh 
[ec2-user@ip-172-31-19-20 terraform]$ ./build.sh 
Initializing modules...
Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 3.14.0 for vpc...
- vpc in .terraform/modules/vpc

Initializing the backend...
...
...
# Please wait for few mins for Terraform
...
...
aws_autoscaling_attachment.tf-webapp-autoscaling-grp: Creation complete after 0s [id=tf-webapp-autoscaling-grp-20220505155957073700000002]
aws_autoscaling_policy.tf-webapp-autoscaling-policy: Creation complete after 1s [id=tf-webapp-autoscaling-policy]

Apply complete! Resources: 39 added, 0 changed, 0 destroyed.

Outputs:

aws_alb_dns = "tf-webapp-alb-1373356092.ap-southeast-1.elb.amazonaws.com"
aws_alb_healthcheck_url = "http://tf-webapp-alb-1373356092.ap-southeast-1.elb.amazonaws.com/healthcheck"
terraform_db_host = "10.0.101.50"
[ec2-user@ip-172-31-19-20 terraform]$ 

### Please wait for few mins then test the healthcheck URL ###
[ec2-user@ip-172-31-19-20 terraform]$ 
[ec2-user@ip-172-31-19-20 terraform]$ curl http://tf-webapp-alb-1373356092.ap-southeast-1.elb.amazonaws.com/healthcheck
OK[ec2-user@ip-172-31-19-20 terraform]$ 
[ec2-user@ip-172-31-19-20 terraform]$ 

### Start Application Test ###
[ec2-user@ip-172-31-19-20 terraform]$ cat request.json 
{
  "url" : "https://yahoo.com/"
}
[ec2-user@ip-172-31-19-20 terraform]$ curl -X POST -H "Content-type: application/json" -d @request.json http://tf-webapp-alb-1373356092.ap-southeast-1.elb.amazonaws.com/newurl
{"_id":"6273f5d6bc00fb0013aeaa67","url":"https://yahoo.com/","shortUrl":"http://tf-webapp-alb-1373356092.ap-southeast-1.elb.amazonaws.com/NxFQSkB1v","urlCode":"NxFQSkB1v","date":"Thu May 05 2022 16:05:42 GMT+0000 (Coordinated Universal Time)","__v":0}[ec2-user@ip-172-31-19-20 terraform]$ 
[ec2-user@ip-172-31-19-20 terraform]$ curl http://tf-webapp-alb-1373356092.ap-southeast-1.elb.amazonaws.com/NxFQSkB1v
Found. Redirecting to https://yahoo.com/[ec2-user@ip-172-31-19-20 terraform]$ 
[ec2-user@ip-172-31-19-20 terraform]$ 
[ec2-user@ip-172-31-19-20 terraform]$ 

```


### Credit 
Webapp is referencing from tutorial https://www.youtube.com/watch?v=Z57566JBaZQ for the Node JS application. I converted it as a container image (changed some configuration) and implemented healthcheck endpoint. The image has been pushed to https://hub.docker.com/r/ixwongit/shorten-url. The following execution is mainly on terraform. Webapp container will be built via userdata to deploy the container.


### Environment clean up
```
[ec2-user@ip-172-31-19-20 test03]$ cd terraform/
[ec2-user@ip-172-31-19-20 terraform]$ chmod +x cleanup.sh 
[ec2-user@ip-172-31-19-20 terraform]$ ./cleanup.sh 
```

### Contributor 

Ivan Wong (2022-May-12)
