# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.hostname = "kafka-berkshelf"

  config.vm.box = "opscode_ubuntu-12.04"
  config.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-12.04_chef-provisionerless.box"

  config.vm.network :private_network, ip: "33.33.33.10"

  config.berkshelf.enabled = true
  config.omnibus.chef_version = :latest

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", 4096]
  end

  config.vm.provision :chef_solo do |chef|
    chef.json = {
      java: {
        jdk_version: 6
      },
      kafka: {
        number_of_brokers: 2
      }
    }

    chef.run_list = [
      "recipe[apt::default]",
      "recipe[kafka::default]"
    ]
  end
end
