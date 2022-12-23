# -*- mode: ruby -*-
# vi: set ft=ruby :

VARS = {
  'SENHA_ROOT'=>'semsenha',
  'BANCO'=>'banco_glpi',
  'USUARIO'=>'usuario_glpi',
  'SENHA'=>'senha_glpi',
  'RANGE'=>'192.168.56.%',

  'SERVIDOR_HAPROXY'=>'192.168.56.10',
  'SERVIDOR_MEMCACHED'=>'192.168.56.11',
  'SERVIDOR_MARIADB'=>'192.168.56.12',
  'SERVIDOR_WEB'=>'192.168.56.13',

  'GLPI_URL'=>'glpi.local',

  #Pode ser conferido na URL https://github.com/glpi-project/glpi/releases
  'VERSAO_GLPI'=>'10.0.5'
}

VMS = [
  {
    :NOME => "haproxy",
    :IP => VARS['SERVIDOR_HAPROXY'],
    :MEM => "1024",
    :CPU => "1",
    :SHELL => "scripts/101-haproxy.sh"
  },{
    :NOME => "memcached",
    :IP => VARS['SERVIDOR_MEMCACHED'],
    :MEM => "1024",
    :CPU => "1",
    :SHELL => "scripts/102-memcached.sh"
  },{
    :NOME => "mariadb",
    :IP => VARS['SERVIDOR_MARIADB'],
    :MEM => "2048",
    :CPU => "2",
    :SHELL => "scripts/103-mariadb.sh"
  },{
    :NOME => "app",
    :IP => VARS['SERVIDOR_WEB'],
    :MEM => "2048",
    :CPU => "2",
    :SHELL => "scripts/104-app.sh"
  }
]

Vagrant.configure("2") do |config|  
  config.vagrant.plugins = ["vagrant-reload", "vagrant-hosts", "vagrant-hostsupdater"]

  IMAGEM = "generic/rocky9"

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.hostsupdater.aliases = {
    VARS['SERVIDOR_HAPROXY'] => VARS['GLPI_URL']
  }

  config.vm.provision "shell", path: "scripts/100-geral.sh"

  VMS.each do |instancia|
    config.vm.define instancia[:NOME] do |w|
      w.vm.box = IMAGEM
      w.vm.hostname = "#{instancia[:NOME]}.#{VARS['GLPI_URL']}"
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
        s.env = VARS.to_hash
        s.path = "#{instancia[:SHELL]}"
      end
    end
  end
end