#!/bin/bash

 #INPOUT
 #nodename,ip, swarm_role, "manager", "keyvalue"

nodename=$1
ip=$2
role=$3
manager=$4
kvserver=$5

echo -e "NODENAME: ${nodename}\nIPADDRESS: ${ip}\nROLE: ${role}\nSWARM MANAGER: ${manager}\nSWARM KVSTORE: ${kvserver}\n"


ResolveFromHosts(){
	ip_from_name=$(cat /etc/hosts|grep " ${1} "|cut -d " " -f1)
}

SetUpKVStore(){
  COMMAND="docker run --restart=always -d -p 8500:8500 --name kv-store progrium/consul -server -bootstrap"
  echo ${COMMAND}
  ${COMMAND}
}

SetUpSwarmAgent(){
  COMMAND="docker run --restart=always  -d --name swarm-agent swarm join --advertise=${ip}:2375 consul://${kvserver}:8500"
  echo ${COMMAND}
  ${COMMAND}
}

SetUpSwarmManager(){
  COMMAND="docker run --restart=always  -d -p 8501:2375 --name swarm-manager swarm manage consul://${kvserver}:8500"
  echo ${COMMAND}
  ${COMMAND}
}

## Configure Docker Engines with Swarm and KeyValue Store Information
echo "DOCKER_OPTS=\"-H unix:///var/run/docker.sock -H tcp://0.0.0.0:2375 --cluster-store=consul://${kvserver}:8500 --cluster-advertise=${ip}:2375\"" >> /etc/default/docker
service docker restart

usermod -aG docker vagrant

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
