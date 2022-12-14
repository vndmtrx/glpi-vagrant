#!/usr/bin/env bash

echo "Instalação do banco MariaDB."
dnf install -y mariadb-server mariadb-server-utils

echo "Ativação do serviço MariaDB."
systemctl enable mariadb.service
systemctl start mariadb.service

echo "Executando comando equivalente a mariadb-secure-installation."
mariadb -uroot <<- EOF
-- set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${SENHA_ROOT}';
-- delete anonymous users
DELETE FROM mysql.user WHERE User='';
-- delete remote root capabilities
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- drop database 'test'
DROP DATABASE IF EXISTS test;
-- also make sure there are lingering permissions to it
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- make changes immediately
FLUSH PRIVILEGES;
EOF

echo "Criando e permissionando banco para o GLPI"
mariadb -uroot -p${SENHA_ROOT} <<- EOF
CREATE DATABASE IF NOT EXISTS ${BANCO} character set utf8;
CREATE USER '${USUARIO}'@'${SERVIDOR}' IDENTIFIED BY '${SENHA}';
GRANT USAGE ON *.* TO '${USUARIO}'@'${SERVIDOR}' IDENTIFIED BY '${SENHA}';
GRANT ALL PRIVILEGES ON ${BANCO}.* TO '${USUARIO}'@'${SERVIDOR}';
FLUSH PRIVILEGES;
EOF

echo "Habilitando suporte ao timezone no MariaDB."
mariadb-tzinfo-to-sql /usr/share/zoneinfo | mariadb -uroot -p${SENHA_ROOT} mysql

echo "Permitindo acesso do usuário ao timezone."
mariadb -uroot -p${SENHA_ROOT} <<- EOF
GRANT SELECT ON mysql.time_zone_name TO '${USUARIO}'@'${SERVIDOR}';
FLUSH PRIVILEGES;
EOF

echo "Liberação da porta 3306 no firewalld."
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd --reload

echo "OK!"
exit 0