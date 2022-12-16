#!/usr/bin/env bash

echo "Instalação do Memcached."
dnf install -y memcached

echo "Configuração do bind da porta do Memcached."
sed -i 's/OPTIONS="-l 127.0.0.1,::1"/OPTIONS="-l 0.0.0.0"/g' /etc/sysconfig/memcached

echo "Liberação da porta 11211 no firewalld."
firewall-cmd --permanent --zone=public --add-port=11211/tcp
firewall-cmd --reload

echo "Ativação do serviço HAProxy."
systemctl enable memcached.service
systemctl start memcached.service

echo "OK!"
exit 0