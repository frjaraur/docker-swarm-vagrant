create:
	vagrant up
clean:
	vagrant destroy -f 
	rm -rf ./tmp_deploying_stage

poweroff:
	vboxmanage controlvm swarm-node1 poweroff
	vboxmanage controlvm swarm-node2 poweroff
	vboxmanage controlvm swarm-manager2 poweroff
	vboxmanage controlvm swarm-manager1 poweroff
	vboxmanage controlvm swarm-keyvalue poweroff

poweron:
	vboxmanage startvm swarm-keyvalue --type headless
	vboxmanage startvm swarm-manager1 --type headless
	vboxmanage startvm swarm-manager2 --type headless
	vboxmanage startvm swarm-node2 --type headless
	vboxmanage startvm swarm-node1 --type headless

