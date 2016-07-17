boxes = [
    {
        :node_name => "swarm-keyvalue",
        :node_ip => "10.0.200.10",
        :node_mem => "1524",
        :node_cpu => "1",
        :swarm_role => "keyvalue",
    },
    {
        :node_name => "swarm-manager1",
        :node_ip => "10.0.200.11",
        :node_mem => "1524",
        :node_cpu => "1",
        :swarm_role=> "manager",
    },
    {
        :node_name => "swarm-manager2",
        :node_ip => "10.0.200.12",
        :node_mem => "1524",
        :node_cpu => "1",
        :swarm_role=> "manager",
    },
    {
        :node_name => "swarm-node1",
        :node_ip => "10.0.200.15",
        :node_mem => "1524",
        :node_cpu => "1",
        :swarm_role=> "node",
    },
    {
        :node_name => "swarm-node2",
        :node_ip => "10.0.200.16",
        :node_mem => "1524",
        :node_cpu => "1",
        :swarm_role=> "node",
    },

]

keyvalue_ip="10.0.200.10"

Vagrant.configure(2) do |config|
  config.vm.box = "ubuntu/trusty64"
  #config.vm.box = "minimal/trusty64"
  config.vm.synced_folder "tmp_deploying_stage/", "/tmp_deploying_stage",create:true

  boxes.each do |opts|
    config.vm.define opts[:node_name] do |config|
      config.vm.hostname = opts[:node_name]
      config.vm.provider "virtualbox" do |v|
        v.name = opts[:node_name]
        v.customize ["modifyvm", :id, "--memory", opts[:node_mem]]
        v.customize ["modifyvm", :id, "--cpus", opts[:node_cpu]]
      end

      # config.vm.network "public_network",
      # bridge: "wlan0" ,
      # use_dhcp_assigned_default_route: true

      config.vm.network "private_network",
      ip: opts[:node_ip],
      virtualbox__intnet: "DOCKER_SWARM"


    #  if opts[:swarm_role] == "keyvalue"
    #	  config.vm.network "forwarded_port", guest: 8500, host: 8500, auto_correct: true
    #  end


      if opts[:swarm_role] == "manager"
    	  config.vm.network "forwarded_port", guest: 3376, host: 3376, auto_correct: true
      end

      # config.vm.provision "shell", inline: <<-SHELL
      #   sudo apt-get update -qq
      # SHELL

      ## INSTALL DOCKER ENGINE
      config.vm.provision "shell", inline: <<-SHELL
        sudo apt-get install -qq curl
        curl -sSL https://get.docker.com/ | sh
        curl -fsSL https://get.docker.com/gpg | sudo apt-key add -
      SHELL

      ## ADD HOSTS
      config.vm.provision "shell", inline: <<-SHELL
        echo "127.0.0.1 localhost" >/etc/hosts
        echo "10.0.200.10 swarm-keyvalue swarm-keyvalue.dockerlab.local" >>/etc/hosts

        echo "10.0.200.11 swarm-manager1 swarm-manager1.dockerlab.local" >>/etc/hosts
        echo "10.0.200.12 swarm-manager2 swarm-manager2.dockerlab.local" >>/etc/hosts

        echo "10.0.200.15 swarm-node1 swarm-node1.dockerlab.local" >>/etc/hosts
        echo "10.0.200.16 swarm-node2 swarm-node2..dockerlab.local" >>/etc/hosts
      SHELL

      nodename=opts[:node_name]
      ip=opts[:node_ip]
      swarm_role=opts[:swarm_role]

      config.vm.provision :shell, :path => 'swarm_install.sh', :args => [ nodename,ip, swarm_role, "manager", keyvalue_ip ]

    end
  end
end
