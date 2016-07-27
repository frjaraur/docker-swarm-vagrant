#!/bin/bash

COMPOSEFILE="$1"
COMPOSEFILE="${COMPOSEFILE:=docker-compose.yml}"

ERR=0

CMD=""


if [ -f /tmp_deploying_stage/infrastructure_provisioned ]
then
	echo -e "\nINFRASTRUCTURE already provisioned\n" && exit 0

fi

[ ! -f $COMPOSEFILE ] && echo -e "ERROR: Compose file ${COMPOSEFILE} does not exist." && exit 1


DOCKER="/usr/bin/docker -H tcp://0.0.0.0:3376  \
	--tlsverify  \
	--tlscacert=/root/.docker/ca.pem \
	--tlscert=/root/.docker/cert.pem \
	--tlskey=/root/.docker/key.pem "

DOCKERCOMPOSE="/usr/local/bin/docker-compose -H tcp://0.0.0.0:3376  \
	--tlsverify  \
	--tlscacert=/root/.docker/ca.pem \
	--tlscert=/root/.docker/cert.pem \
	--tlskey=/root/.docker/key.pem "


# Create infrastructure network
CMD="${DOCKER} network create infrastructure"

echo -e "\n${CMD}\n"

${CMD}
[ $? -ne 0 ] && ERR=$(( $ERR + 1 ))

# Compose infrastructure
CMD="${DOCKERCOMPOSE} -f ${COMPOSEFILE} --project-name 'infrastructure' up -d"

echo -e "\n${CMD}\n"

${CMD}
[ $? -ne 0 ] && ERR=$(( $ERR + 1 ))


[ $ERR -eq 0 ] &&  echo -e "INFRASTRUCTURE" > /tmp_deploying_stage/infrastructure_provisioned  && exit 0

echo -e "\nAn error ocurred during infrastructure provision\n"
