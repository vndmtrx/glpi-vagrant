#!/usr/bin/env bash

echo "Instalação de módulos de gerenciamento de disco no Cockpit"
dnf install -y cockpit-file-sharing cockpit-navigator

echo "Instalação do NFS"
dnf install nfs-utils

echo "Criação da pasta para uso do GLPI"
mkdir -p /mnt/nfs/share-glpi
chown nobody:nobody /mnt/nfs/share-glpi
chmod 0777 /mnt/nfs/share-glpi

echo "Implantação das configurações do NFS"
cat <<EOF | tee -a /etc/exports.d/glpi > /dev/null
/mnt/nfs/share-glpi 192.168.56.0/24(rw,sync,no_subtree_check)
EOF

echo "Aplicação das configurações do NFS"
exportfs -ra

echo "Ativação do serviço NFS"
systemctl enable nfs-server.service
systemctl start nfs-server.service

echo "OK!"
exit 0