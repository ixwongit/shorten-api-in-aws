#!/bin/bash
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo wget https://github.com/docker/compose/releases/download/v2.4.1/docker-compose-linux-x86_64
sudo mv docker-compose-linux-x86_64 /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo usermod -aG docker ec2-user
sudo su - ec2-user
cat <<EOF > /home/ec2-user/docker-compose.yml
version: '3.1'

services:
  shorten-url:
    image: ixwongit/shorten-url:v0.1
    ports:
      - "5000:5000"
    environment:
      MONGOURL: mongodb://root:password@${terraform_db_host}:27017/test?authSource=admin
      BASEURL: http://${terraform_webapp_alb_url}
    restart: always
EOF
docker-compose -f /home/ec2-user/docker-compose.yml up -d
