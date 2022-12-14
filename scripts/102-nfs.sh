#!/usr/bin/env bash

echo "Instalação de módulos de gerenciamento de disco no Cockpit."
dnf install -y cockpit-navigator

echo "Instalação do NFS."
dnf install -y nfs-utils

echo "Criação da pasta para uso do GLPI."
mkdir -p /mnt/nfs/share-glpi
chown nobody:nobody /mnt/nfs/share-glpi
chmod 0777 /mnt/nfs/share-glpi

echo "Implantação das configurações do NFS."
cat << EOF | tee -a /etc/exports.d/glpi.exports > /dev/null
/mnt/nfs/share-glpi 192.168.56.0/24(rw,sync,no_subtree_check)
EOF

echo "Aplicação das configurações do NFS."
exportfs -ra
showmount --exports

echo "Ativação do serviço NFS."
systemctl enable nfs-server.service
systemctl start nfs-server.service

echo "Liberação do serviço NFS no firewalld."
firewall-cmd --permanent --zone=public --add-service mountd
firewall-cmd --permanent --zone=public --add-service rpc-bind
firewall-cmd --permanent --zone=public --add-service nfs
firewall-cmd --reload

echo "OK!"
exit 0