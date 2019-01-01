# -*- mode: ruby -*-
# vi: set ft=ruby :

if not Vagrant.has_plugin? "vagrant-ignition"
  abort "The vagrant-ignition plugin is required. Aborting..."
end

Vagrant.configure("2") do |config|
  config.ignition.enabled = true

  config.vm.provider "virtualbox" do |virtualbox|
    virtualbox.cpus = 2
    virtualbox.memory = 1024
  end

  config.vm.define "database" do |database|
    database.vm.box = "coreos-stable"
    database.vm.hostname = database.ignition.hostname = "database"
    database.ignition.drive_name = "database"
    database.ignition.path = "coreos-vagrant-virtualbox.ign"

    ip = "172.17.8.100"
    database.vm.network :private_network, ip: ip
    database.ignition.ip = ip

    database.vm.provision "file", source: "./coreos/database", destination: "/tmp/coreos"
    database.vm.provision "shell", inline: <<-SCRIPT
      sudo rsync -r /tmp/coreos/ /
      /var/opt/starterkit/bin/provision-database
    SCRIPT
  end

  (1..3).each do |i|
    config.vm.define name = "instance-%02d" % i do |instance|
      instance.vm.box = "coreos-stable"
      instance.vm.hostname = instance.ignition.hostname = name
      instance.ignition.drive_name = name
      instance.ignition.path = "coreos-vagrant-virtualbox.ign"

      ip = "172.17.8.#{i+100}"
      instance.vm.network :private_network, ip: ip
      instance.ignition.ip = ip

      instance.vm.provision "file", source: "./coreos/instance", destination: "/tmp/coreos"
      instance.vm.provision "shell", inline: <<-SCRIPT
        sudo rsync -r /tmp/coreos/ /
        /var/opt/starterkit/bin/provision-instance
      SCRIPT
    end
  end

  config.vm.define "balancer" do |balancer|
    balancer.vm.box = "coreos-stable"
    balancer.vm.hostname = balancer.ignition.hostname = "balancer"
    balancer.ignition.drive_name = "balancer"
    balancer.ignition.path = "coreos-vagrant-virtualbox.ign"

    ip = "172.17.8.200"
    balancer.vm.network :private_network, ip: ip
    balancer.ignition.ip = ip

    [8080, 8443, 8888].each do |port|
      balancer.vm.network "forwarded_port", host: port, guest: port, guest_ip: ip, protocol: "tcp"
    end

    balancer.vm.provision "file", source: "./coreos/balancer", destination: "/tmp/coreos"
    balancer.vm.provision "shell", inline: <<-SCRIPT
      sudo rsync -r /tmp/coreos/ /
      /var/opt/starterkit/bin/provision-balancer
    SCRIPT
  end
end
