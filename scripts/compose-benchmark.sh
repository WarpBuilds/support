#!/bin/bash

echo "Generating ssh key"
ssh-keygen -t rsa -b 4096 -C "ci@example.com" -N "" -f my_ci_key

export COMPOSE_LOG_LEVEL=DEBUG

# Start Docker Compose services in detached mode
docker compose up -d

# Initialize flags to indicate if MySQL and Redis are up
mysql_up=false
redis_up=false
pg_up=false
elasticsearch_up=false
sftp_up=false
gotenberg_up=false

# Record the start time in nanoseconds
start_time=$(date +%s%N)

# Loop until both services are up
while [ "$mysql_up" = false ] || \
    [ "$redis_up" = false ] || \
    [ "$pg_up" = false ] || \
    [ "$elasticsearch_up" = false ] || \
    [ "$sftp_up" = false ] || \
    [ "$gotenberg_up" = false ]; do
  # Current time in nanoseconds
  current_time=$(date +%s%N)
  
  # Calculate elapsed time in milliseconds
  elapsed=$(( (current_time - start_time) / 1000000 ))
  
  # Try connecting to MySQL if it's not up yet
  if [ "$mysql_up" = false ]; then
    # # Use the mysql client to attempt a connection
    # if mysql -hlocalhost -umyuser -pmypassword -e "SELECT 1" > /dev/null 2>&1; then
    #   mysql_up=true
    #   echo "MySQL is up after $elapsed milliseconds."
    # fi
    # Use the mysql client to attempt a connection
    if mysql -h 127.0.0.1 -u myuser -p'mypassword' mydatabase -e 'SELECT CURRENT_TIMESTAMP;' > /dev/null 2>&1; then
      mysql_up=true
      echo "MySQL is up after $elapsed milliseconds."
    fi
  fi
  
  # Try pinging Redis if it's not up yet
  if [ "$redis_up" = false ]; then
    # Use the redis-cli to attempt a ping
    if redis-cli -h localhost ping > /dev/null; then
      redis_up=true
      echo "Redis is up after $elapsed milliseconds."
    fi
  fi

  if [ "$pg_up" = false ]; then
    if pg_isready -U your_user -d your_database -h localhost -p 5432 > /dev/null; then
      pg_up=true
      echo "Postgres is up after $elapsed milliseconds."
    fi
  fi

if [ "$elasticsearch_up" = false ]; then
    # Elasticsearch ping check
    if curl -s "localhost:9200" > /dev/null; then
      elasticsearch_up=true
      echo "Elasticsearch is up after $elapsed milliseconds."
    fi
  fi

  if [ "$sftp_up" = false ]; then
    # Attempt to connect to SFTP using ssh command
    if echo "exit" | sftp -oBatchMode=yes -oConnectTimeout=5 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null  -i ./my_ci_key -P 2222 user@localhost; then
    # if ssh -oBatchMode=yes -oConnectTimeout=5 -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ./my_ci_key -p 2222 user@localhost exit; then
      sftp_up=true
      echo "SFTP is up after $elapsed milliseconds."
    fi
  fi

  if [ "$gotenberg_up" = false ]; then
    # Gotenberg health check via its HTTP API
    if curl -s "localhost:3000/health" > /dev/null; then
      gotenberg_up=true
      echo "Gotenberg is up after $elapsed milliseconds."
    fi
  fi

  # Sleep for a short period to prevent tight looping
  sleep 0.1
done

echo "All services are up."