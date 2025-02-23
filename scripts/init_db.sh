#!/usr/bin/env bash

set -x
set -eo pipefail


if ! [ -x "$(command -v mysql)" ]; then
    echo >&2 "Error: mysql is not installed."
    exit 1
fi

if ! [ -x "$(command -v sqlx)" ]; then
    echo >&2 "Error: sqlx is not installed."
    echo >&2 "Use:"
    echo >&2 "    cargo install --version='0.8.3' sqlx-cli \
    --no-default-features --features rustls,mysql"
    echo >&2 "to install it."
    exit 1
fi


DB_USER="${MYSQL_USER:=root}"
DB_PASSWORD="${MYSQL_PASSWORD:=password}"
DB_NAME="${MYSQL_DATABASE:=newsletter}"
DB_PORT="${MYSQL_PORT:=3306}"
DB_HOST="${MYSQL_HOST:=localhost}"

if [[ -z "${SKIP_DOCKER}" ]]; 
then
    # if a mysql container is running, prunt instructions to kill it and exit
    RUNNING_MYSQL_CONTAINER=$(docker ps --filter 'name=mysql' --format '{{.ID}}')
    if [[ -n $RUNNING_MYSQL_CONTAINER ]]; then
        echo >&2 "there is a mysql container already running, kill it with"
        echo >&2 "    docker kill ${RUNNING_MYSQL_CONTAINER}"
        exit 1
    fi
    CONTAINER_NAME="mysql_$(date '+%s')"
    # Launch mysql using Docker
    docker run \
        --name "${CONTAINER_NAME}" \
        -e MYSQL_ROOT_PASSWORD=${DB_PASSWORD} \
        -e MYSQL_PASSWORD=${DB_PASSWORD} \
        -e MYSQL_DATABASE=${DB_NAME} \
        --health-cmd="mysqladmin ping -h localhost -u ${DB_USER} --password=${DB_PASSWORD} || exit 1" \
        --health-interval=1s \
        --health-timeout=5s \
        --health-retries=5 \
        -p "${DB_PORT}":3306 \
        -d mysql \
        --max-connections=1000
fi

# Keep pinging mysql until it's ready to accept commands
export PASSWORD="${DB_PASSWORD}"
until mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASSWORD}" -e "SELECT 1" &> /dev/null; do
  >&2 echo "Mysql is still unavailable - sleeping"
  sleep 1
done 
>&2 echo "Mysql is up and running on port ${DB_PORT}!"
  
DATABASE_URL="mysql://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
export DATABASE_URL

sqlx database create
sqlx migrate run
# sqlx migrate add create_subscription_table

>&2 echo "Mysql has been migrated, ready to go!"