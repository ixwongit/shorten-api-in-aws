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
  mongo:
    image: mongo
    restart: always
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: password
      MONGO_INITDB_DATABASE: test
EOF
docker-compose -f /home/ec2-user/docker-compose.yml up -d
