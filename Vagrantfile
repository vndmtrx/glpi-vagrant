# -*- mode: ruby -*-
# vi: set ft=ruby :

IMAGEM = "generic/rocky9"

Vagrant.configure("2") do |config|
  
  config.vagrant.plugins = ["vagrant-reload", "vagrant-hosts"]

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.define "haproxy" do |lb|
    lb.vm.box = IMAGEM
    lb.vm.hostname = "haproxy.glpi.local"
    lb.vm.network "private_network", :ip => "192.168.56.10", :adapter => 2
    lb.vm.network "forwarded_port", guest: 9090, host: 9010
    lb.vm.provision :hosts, :sync_hosts => true
    lb.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 1
      v.default_nic_type = "virtio"
      v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
      v.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
    end

    lb.vm.provision "shell", path: "scripts/100-geral.sh"
    lb.vm.provision "shell", path: "scripts/101-haproxy.sh"
  end

  config.vm.define "nfs" do |nfs|
    nfs.vm.box = IMAGEM
    nfs.vm.hostname = "nfs.glpi.local"
    nfs.vm.network "private_network", :ip => "192.168.56.11", :adapter => 2
    nfs.vm.network "forwarded_port", guest: 9090, host: 9011
    nfs.vm.provision :hosts, :sync_hosts => true
    nfs.vm.provider "virtualbox" do |v|
      v.memory = 1024
      v.cpus = 1
      v.default_nic_type = "virtio"
      v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
      v.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
    end

    nfs.vm.provision "shell", path: "scripts/100-geral.sh"
    #nfs.vm.provision "shell", path: "scripts/102-nfs.sh"
  end

  config.vm.define "mariadb" do |db|
    db.vm.box = IMAGEM
    db.vm.hostname = "mariadb.glpi.local"
    db.vm.network "private_network", :ip => "192.168.56.12", :adapter => 2
    db.vm.network "forwarded_port", guest: 9090, host: 9012
    db.vm.provision :hosts, :sync_hosts => true
    db.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 2
      v.default_nic_type = "virtio"
      v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
      v.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
    end

    #db.vm.provision "shell", path: "scripts/100-geral.sh"
    #db.vm.provision "shell", path: "scripts/103-mariadb.sh"
  end

  config.vm.define "app" do |app|
    app.vm.box = IMAGEM
    app.vm.hostname = "app.glpi.local"
    app.vm.network "private_network", :ip => "192.168.56.13", :adapter => 2
    app.vm.network "forwarded_port", guest: 9090, host: 9013
    app.vm.provision :hosts, :sync_hosts => true
    app.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 1
      v.default_nic_type = "virtio"
      v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
      v.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
    end

    app.vm.provision "shell", path: "scripts/100-geral.sh"
    app.vm.provision "shell", path: "scripts/104-app.sh"
  end
end
