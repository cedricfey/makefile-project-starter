#!/bin/sh

stage=${1:-'default'}

cat <<EOF
## base
APP_NAME=<APP_NAME>
PROJECT_NAME=<PROJECT_NAME>
SCALINGO_APP_NAME=<SCALINGO_APP_NAME>-$stage
COMPOSE_PROJECT_NAME=<PROJECT_NAME>-$stage
STAGE=$stage
EOF

case $stage in
	'default'|'test')
		cat <<-EOF
		## docker image to run using make's start target
		APP_IMAGE=<APP_IMAGE>
		EOF
		;;

	*)
		echo "Unknown stage $stage"
		exit 1
		;;
esac

if [ "$stage" = "test" ]; then
	cat <<-EOF
	LOCAL_PORT_RAILS=13000
	LOCAL_PORT_CADDY=18080
	LOCAL_PORT_PUMA=19292
	EOF
fi
