#!/bin/bash

echo "Remove existed container"
docker-compose -f /home/ubuntu/deploy/docker-compose.yml down || true
