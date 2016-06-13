#!/bin/bash

ACTION=$1

NODE=$2

ACTION="$(echo ${ACTION}|tr '[A-Z]' '[a-z]')"

SWARM_NODES="keyvalue manager node2 node3"

[ -n "$NODE" ] && SWARM_NODES="${NODE}"

echo -e "\nNODES: ${SWARM_NODES}\nACTION: ${ACTION}\n"

case ${ACTION} in

	down|off|poweroff|stop)
		for nodes in ${SWARM_NODES};
		do 
			[ ! -f tmp_deploying_stage/${nodes}.swarm_node_provisioned ] && echo "Node ${nodes} not provisioned..." && continue
			VBoxManage controlvm ${nodes} poweroff;
		done
	;;
	start|on|up)
		for nodes in ${SWARM_NODES};
		do 
			[ ! -f tmp_deploying_stage/${nodes}.swarm_node_provisioned ] && echo "Node ${nodes} not provisioned..." && continue
			VBoxManage startvm ${nodes} --type headless;
		done
	;;
esac
