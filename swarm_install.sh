#!/bin/bash

 #INPOUT
 #nodename,ip, swarm_role, "manager", "keyvalue"

nodename=$1
ip=$2
role=$3
manager=$4
kvserver=$5
iphostonly=$6

PASSPHRASE="swarm"
ERR=0

echo -e "NODENAME: ${nodename}\nIPADDRESS: ${ip}\nROLE: ${role}\nSWARM MANAGER: ${manager}\nSWARM KVSTORE: ${kvserver}\n"

if [ -f /tmp_deploying_stage/${nodename}.swarm_node_provisioned ]
then
	echo -e "\nNODE ${nodename} already provisioned on SWARM\n" && exit 0

fi

ResolveFromHosts(){
	ip_from_name=$(cat /etc/hosts|grep " ${1} "|cut -d " " -f1)
}

SetUpKVStore(){
  COMMAND="docker run --restart=always -d -p 8500:8500 --name kv-store progrium/consul -server -bootstrap"
  echo ${COMMAND}
  ${COMMAND}
  [ $? -ne 0 ] && ERR=$(( $ERR + 1 ))
}

SetUpSwarmAgent(){
  COMMAND="docker run --restart=always  -d --name swarm-agent -v /etc/docker/certs.d:/certs:ro swarm \
	join \
	--advertise=${ip}:2376 consul://${kvserver}:8500"
  echo ${COMMAND}
  ${COMMAND}
  [ $? -ne 0 ] && ERR=$(( $ERR + 1 ))
}

SetUpSwarmManager(){
  COMMAND="docker run --restart=always  -d -p 3376:3376 --name swarm-manager 	-v /etc/docker/certs.d:/certs:ro swarm \
	manage --replication --advertise=${ip}:2376 \
	--tlsverify --tlscacert=/certs/ca.pem --tlscert=/certs/cert.pem --tlskey=/certs/key.pem \
	--host=0.0.0.0:3376 consul://${kvserver}:8500"
  echo ${COMMAND}
  ${COMMAND}
  [ $? -ne 0 ] && ERR=$(( $ERR + 1 ))
}



## Timezone and NTP
apt-get -qq install chrony
timedatectl set-timezone Europe/Madrid

## Generate TLS certs

echo "Enabling TLS on Docker Engines"

mkdir -p /etc/docker/certs.d && chmod 750 /etc/docker/certs.d
mkdir /root/.docker && chmod 750 /root/.docker

echo "Certificates Authority"

if [ ! -f /tmp_deploying_stage/ca.pem ]
then
	## Generate CA
	docker run --rm --net=none -e SERVERNAME=${nodename} \
	-e SERVERIPS="${ip}},0.0.0.0" -e PASSPHRASE="${PASSPHRASE}"  \
	-e CLIENTNAME="${nodename}" -v /etc/docker/certs.d:/certs \
	frjaraur/docker-simple-tlscerts generate_CA

	cp -p /etc/docker/certs.d/ca.pem /tmp_deploying_stage/ca.pem && \
	cp -p /etc/docker/certs.d/ca-key.pem /tmp_deploying_stage/ca-key.pem

else
	cp /tmp_deploying_stage/ca.pem /etc/docker/certs.d/ca.pem && \
	cp /tmp_deploying_stage/ca-key.pem /etc/docker/certs.d/ca-key.pem && \
	chown root:root /etc/docker/certs.d/ca.pem && \
	chmod -v 0444 /etc/docker/certs.d/ca.pem

fi

echo "Certificates for Server"

	## Generate Server Keys
	docker run --rm --net=none -e SERVERNAME=${nodename} \
	-e SERVERIPS="${ip},${iphostonly},0.0.0.0,127.0.0.1" -e PASSPHRASE="${PASSPHRASE}"  \
	-e CLIENTNAME="${nodename}" -v /etc/docker/certs.d:/certs \
	frjaraur/docker-simple-tlscerts generate_serverkeys

echo "Certificates for Client"


	## Generate Client Keys
	docker run --rm --net=none -e SERVERNAME=${nodename} \
	-e SERVERIPS="${ip},0.0.0.0,127.0.0.1" -e PASSPHRASE="${PASSPHRASE}"  \
	-e CLIENTNAME="${nodename}" -v /etc/docker/certs.d:/certs \
	frjaraur/docker-simple-tlscerts generate_clientkeys

	chmod -v 0400 /etc/docker/certs.d/*key.pem
	chmod -v 0444 /etc/docker/certs.d/ca.pem /etc/docker/certs.d/*cert.pem

	mv /etc/docker/certs.d/server-key.pem /etc/docker/certs.d/key.pem
	mv /etc/docker/certs.d/server-cert.pem /etc/docker/certs.d/cert.pem

	mv /etc/docker/certs.d/client-key.pem /root/.docker/key.pem
	mv /etc/docker/certs.d/client-cert.pem /root/.docker/cert.pem
	cp -p /etc/docker/certs.d/ca.pem /root/.docker/ca.pem

## Configure Docker Engines with Swarm. TLS and KeyValue Store Information
#echo "DOCKER_TLS_VERIFY=1" >> /etc/default/docker
#echo "DOCKER_CERT_PATH=\"/etc/docker/certs.d\"" >> /etc/default/docker
echo "DOCKER_OPTS=\"-H unix:///var/run/docker.sock -H tcp://0.0.0.0:2376  \
	--tlsverify  \
	--tlscacert=/etc/docker/certs.d/ca.pem \
	--tlscert=/etc/docker/certs.d/cert.pem \
	--tlskey=/etc/docker/certs.d/key.pem \
	--cluster-store=consul://${kvserver}:8500 --cluster-advertise=${ip}:2376\"" >> /etc/default/docker


cp -p /etc/docker/certs.d/ca.pem /usr/share/ca-certificates/ca.pem

update-ca-certificates

service docker restart

case ${role} in
  keyvalue)

      SetUpKVStore

  ;;

  manager)

      SetUpSwarmAgent
      SetUpSwarmManager

  ;;

  node)

      SetUpSwarmAgent


  ;;

esac


## Compose
curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


echo "export DOCKER_TLS_VERIFY=1" >>/tmp_deploying_stage/env.sh
echo "export DOCKER_CERT_PATH=/root/.docker" >>/tmp_deploying_stage/env.sh

provisioned="nodename: ${nodename}\nip: ${ip}\nrole: ${role}\nmanager: ${nmanager}\kvserver: ${kvserver}\niphostonly: ${iphostonly}\n"


[ $ERR -eq 0 ] &&  echo -e ${provisioned} > /tmp_deploying_stage/${nodename}.swarm_node_provisioned && exit 0

echo "\nAn error ocurred during node ${nodename} provision on SWARM\n"
