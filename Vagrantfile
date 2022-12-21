# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  config.vagrant.plugins = ["vagrant-reload", "vagrant-hosts", "vagrant-env", "vagrant-hostsupdater"]
  config.env.enable

  IMAGEM = "generic/rocky9"

  VMS = [
    {
      :NOME => "haproxy",
      :IP => ENV['SERVIDOR_HAPROXY'],
      :MEM => "1024",
      :CPU => "1",
      :SHELL => "scripts/101-haproxy.sh"
    },{
      :NOME => "memcached",
      :IP => ENV['SERVDOR_MEMCACHED'],
      :MEM => "1024",
      :CPU => "1",
      :SHELL => "scripts/102-memcached.sh"
    },{
      :NOME => "mariadb",
      :IP => ENV['SERVDOR_MARIADB'],
      :MEM => "2048",
      :CPU => "2",
      :SHELL => "scripts/103-mariadb.sh"
    },{
      :NOME => "app",
      :IP => ENV['SERVIDOR_WEB'],
      :MEM => "2048",
      :CPU => "2",
      :SHELL => "scripts/104-app.sh"
    }
  ]

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.hostsupdater.aliases = {
    ENV['SERVIDOR_HAPROXY'] => ENV['GLPI_URL']
  }

  config.vm.provision "shell", path: "scripts/100-geral.sh"

  VMS.each do |instancia|
    config.vm.define instancia[:NOME] do |w|
      w.vm.box = IMAGEM
      w.vm.hostname = "#{instancia[:NOME]}.#{ENV['GLPI_URL']}"
      w.vm.network "private_network", :ip => instancia[:IP], :adapter => 2
      w.vm.provision :hosts, :sync_hosts => true
      w.vm.provider "virtualbox" do |v|
        v.memory = instancia[:MEM]
        v.cpus = instancia[:CPU]
        v.default_nic_type = "virtio"
        v.customize ["modifyvm", :id, "--natnet1", "10.254.0.0/16"]
        v.customize ["modifyvm", :id, "--natdnsproxy1", "off"]
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "off"]
        v.linked_clone = true
      end

      w.vm.provision :shell do |s|
        s.env = {
          SENHA_ROOT:ENV['SENHA_ROOT'],
          BANCO:ENV['BANCO'],
          USUARIO:ENV['USUARIO'],
          SENHA:ENV['SENHA'],
          RANGE:ENV['RANGE'],

          SERVIDOR_HAPROXY:ENV['SERVIDOR_HAPROXY'],
          SERVDOR_MEMCACHED:ENV['SERVDOR_MEMCACHED'],
          SERVDOR_MARIADB:ENV['SERVDOR_MARIADB'],
          SERVIDOR_WEB:ENV['SERVIDOR_WEB'],

          GLPI_URL:ENV['GLPI_URL'],

          VERSAO_GLPI:ENV['VERSAO_GLPI']
        }
        s.path = "#{instancia[:SHELL]}"
      end
    end
  end
end