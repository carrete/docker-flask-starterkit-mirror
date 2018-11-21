# -*- mode: ruby -*-
# vi: set ft=ruby :

if not Vagrant.has_plugin? "vagrant-ignition"
  abort "The vagrant-ignition plugin is required. Aborting..."
end

Vagrant.configure("2") do |config|
  config.ignition.enabled = true
  config.ignition.path = "config.ign"

  config.vm.network "private_network", type: "dhcp"

  config.vm.provision "file", source: "./coreos", destination: "/tmp/coreos"

  config.vm.provision "shell", inline: <<-SCRIPT
    sudo rsync -r /tmp/coreos/ /
  SCRIPT

  config.vm.define "postgres" do |postgres|
    postgres.vm.box = "coreos-stable"
    postgres.vm.hostname = postgres.ignition.hostname = ENV["POSTGRES_HOSTNAME"]
    postgres.ignition.drive_name = "postgres"

    postgres.vm.provision "shell", inline: <<-SCRIPT
      /var/opt/starterkit/bin/provision-postgres
    SCRIPT
  end

  config.vm.define "instance" do |instance|
    instance.vm.box = "coreos-stable"
    instance.vm.hostname = instance.ignition.hostname = "instance"
    instance.ignition.drive_name = "instance"

    instance.vm.provision "shell", inline: <<-SCRIPT
      /var/opt/starterkit/bin/provision-instance
    SCRIPT
  end
end
