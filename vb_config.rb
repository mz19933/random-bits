# https://dev.to/kennibravo/vagrant-for-beginners-getting-started-with-examples-jlm
NUM_NODES = 3
NUM_CONTROLLER_NODE = 2
IP_NTW = "192.168.56."
CONTROLLER_IP_START = 3
NODE_IP_START = 5

Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/jammy64"

    (1..NUM_NODES).each do |i|
        config.vm.define "target0#{i}" do |node|
            node.vm.provider "virtualbox" do |vb|
                vb.name = "target0#{i}"
                vb.memory = 2048
                vb.cpus = 2
            end

            node.vm.hostname = "worker#{i}"
            node.vm.network "private_network", ip: IP_NTW + "#{NODE_IP_START + i}"
            node.vm.network "forwarded_port", guest: 22, host: "#{2720 + i}"
        end
    end

    i = 0

    (1..NUM_CONTROLLER_NODE).each do |i|
        config.vm.define "nodecontroller" do |node|
            node.vm.provider "virtualbox" do |vb|
                vb.name = "nodecontroller"
                vb.memory = 2048
                vb.cpus = 1
            end

            node.vm.hostname = "controller#{i}"
            node.vm.network "private_network", ip: IP_NTW + "#{CONTROLLER_IP_START + i}"
            node.vm.network "forwarded_port", guest: 22, host: "#{2710 + i}"
        end
    end
end