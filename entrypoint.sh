#!/bin/sh -l

docker_run="docker run"

if [[ -n "$INPUT_PREPOPULATE" ]]; then
    echo "Populating LDAP server with data..."
    docker_run="$docker_run --volume $GITHUB_WORKSPACE/$INPUT_PREPOPULATE:/etc/ldap.dist/prepopulate"
fi

docker_run="$docker_run -e SLAPD_DOMAIN=$INPUT_DOMAIN"
docker_run="$docker_run -e SLAPD_PASSWORD=$INPUT_ADMINPASSWORD"

docker_run="$docker_run -d -p 389:389 dinkel/openldap"

echo "Run command: $docker_run"

sh -c "$docker_run"