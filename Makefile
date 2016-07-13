create:
	vagrant up
clean:
	vagrant destroy -f 
	rm -rf ./tmp_deploying_stage

poweroff:
	vboxmanage controlvm swarm-node3 poweroff
	vboxmanage controlvm swarm-node2 poweroff
	vboxmanage controlvm swarm-manager poweroff
	vboxmanage controlvm swarm-keyvalue poweroff

poweron:
	vboxmanage startvm swarm-keyvalue --type headless
	vboxmanage startvm swarm-manager --type headless
	vboxmanage startvm swarm-node2 --type headless
	vboxmanage startvm swarm-node3 --type headless

