#!/usr/bin/env bash

echo "Instalação dos repositórios REMI para o Rocky Linux 9."
dnf install -y http://rpms.remirepo.net/enterprise/remi-release-9.rpm

echo "Instalação de módulos do Cockpit para uso do app."
dnf install -y cockpit-navigator

echo "Habilitação do módulo do PHP 8.1 do REMI para instalação."
dnf module enable -y php:remi-8.1

echo "Instalação do PHP 8.1."
dnf install -y php

echo "Instalação do Apache."
dnf install -y httpd httpd-tools

echo "Instalação do mod_security no Apache."
dnf install -y mod_security

echo "Configuração do VirtualHost do GLPI."
cat << EOF | tee /etc/httpd/conf.d/001-glpi.conf
<VirtualHost *:80>
    DocumentRoot "/opt/glpi/"
    ServerName GLPI
</VirtualHost>

<Directory /opt/glpi/>
    Options Indexes FollowSymLinks
    AllowOverride All
    Require all granted
</Directory>
EOF

echo "Instalação das dependências do GLPI"
dnf install -y php-pecl-mysql php-gd php-intl php-ldap php-pecl-zip

echo "Download do GLPI na versão ${VERSAO_GLPI}."
#wget -O- https://github.com/glpi-project/glpi/releases/download/${VERSAO_GLPI}/glpi-${VERSAO_GLPI}.tgz | tar -zxv -C /var/www/html/
wget -O- https://github.com/glpi-project/glpi/releases/download/${VERSAO_GLPI}/glpi-${VERSAO_GLPI}.tgz | tar -zxv -C /opt/

echo "Ajuste das permissões dos arquivos."
chown -Rf apache. /opt/glpi
find /opt/glpi -type d -exec chmod 755 {} \;
find /opt/glpi -type f -exec chmod 644 {} \;

echo "Alterações de configuração do PHP."
#sed -i 's,;date.timezone =,date.timezone = America/Sao_Paulo,g' /etc/php.ini
#sed -i 's,upload_max_filesize = 2M,upload_max_filesize = 20M,g' /etc/php.ini
cat << EOF | tee /etc/php.d/00-glpi.ini
[PHP]
upload_max_filesize = 20M

[Session]
session.cookie_httponly = On
session.cookie_samesite = Lax

[Date]
date.timezone = America/Sao_Paulo
EOF

# https://dwalsh.fedorapeople.org/SELinux/httpd_selinux.html
# https://www.serverlab.ca/tutorials/linux/web-servers-linux/configuring-selinux-policies-for-apache-web-servers/
echo "Liberações de acesso do Apache, PHP e GLPI no SELinux."
setsebool -P httpd_can_sendmail 1
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_connect_db 1
setsebool -P httpd_can_connect_ldap 1
setsebool -P httpd_use_nfs 1
#setsebool -P httpd_unified 1

echo "Ajustes das permissões das pastas do GLPI, no SELinux."
semanage fcontext -a -t httpd_sys_content_t "/opt/glpi(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/opt/glpi/files(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/opt/glpi/config(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/opt/glpi/marketplace(/.*)?"
semanage fcontext -a -t httpd_log_t "/opt/glpi/files/_log(/.*)?"
restorecon -F -R -v /opt/glpi

echo "Liberação do serviço http, no firewalld."
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --reload

echo "Ativação do serviço Apache."
systemctl enable httpd.service
systemctl start httpd.service

echo "Configuração inicial do banco de dados."
php /opt/glpi/bin/console db:install \
        -L pt_BR -H ${SERVIDOR} \
        -d ${BANCO} \
        -u ${USUARIO} \
        -p ${SENHA} \
        --enable-telemetry --no-interaction

echo "Remoção do script de backup do GLPI."
rm -rf /opt/glpi/install/install.php

echo "---------------------------------------"
echo "Informações de configuração para o GLPI"
echo "---------------------------------------"
echo "Banco de dados do GLPI: ${BANCO}"
echo "Endereço do banco: ${SERVIDOR}"
echo "Usuário do banco: ${USUARIO}"
echo "Senha do banco: ${SENHA}"
echo "---------------------------------------"

echo "OK!"
exit 0