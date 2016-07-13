run:
	vagrant up
clean:
	vagrant destroy -f 
	rm -rf ./tmp_deploying_stage
