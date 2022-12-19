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
dnf install -y mod_security mod_security_crs

echo "Instalação do cliente do MariaDB."
dnf install -y mariadb

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

echo "Instalação das dependências do GLPI."
dnf install -y php-pecl-mysql php-gd php-intl php-ldap php-pecl-zip php-pecl-memcached

echo "Download do GLPI na versão ${VERSAO_GLPI}."
#wget -O- https://github.com/glpi-project/glpi/releases/download/${VERSAO_GLPI}/glpi-${VERSAO_GLPI}.tgz | tar -zxv -C /var/www/html/
curl -fsSL https://github.com/glpi-project/glpi/releases/download/${VERSAO_GLPI}/glpi-${VERSAO_GLPI}.tgz | tar -zx -C /opt/

echo "Criação das pastas de configuração, log e arquivos do GLPI em pasta fora do alcance do Apache."
mkdir /var/lib/glpi
mv /opt/glpi/config /var/lib/glpi/config
mv /opt/glpi/files/_log /var/lib/glpi/log
mv /opt/glpi/files /var/lib/glpi/files

echo "Configuração de alteração das pastas de configuração, log e arquivos para o GLPI."
cat << "EOF" | tee /opt/glpi/inc/downstream.php
<?php
define('GLPI_CONFIG_DIR', '/var/lib/glpi/config');

if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
   require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF
cat << "EOF" | tee /var/lib/glpi/config/local_define.php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi/files');
define('GLPI_LOG_DIR', '/var/lib/glpi/log');
EOF

echo "Alterações de configuração do PHP."
#sed -i 's,;date.timezone =,date.timezone = America/Sao_Paulo,g' /etc/php.ini
#sed -i 's,upload_max_filesize = 2M,upload_max_filesize = 20M,g' /etc/php.ini
cat << EOF | tee /etc/php.d/00-glpi.ini
[PHP]
upload_max_filesize = 20M
max_execution_time = 600

[Session]
session.auto_start = off
session.use_trans_sid = 0
session.cookie_httponly = On
session.cookie_samesite = Lax

[Date]
date.timezone = America/Sao_Paulo
EOF

echo "Liberações de acesso do Apache, PHP e GLPI no SELinux."
setsebool -P httpd_can_sendmail 1
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_connect_db 1
setsebool -P httpd_can_connect_ldap 1
setsebool -P httpd_can_network_memcache 1

echo "Checagem dos requerimentos de sistema para a instalação do GLPI."
php /opt/glpi/bin/console glpi:system:check_requirements

echo "Configuração inicial do banco de dados."
php /opt/glpi/bin/console db:install \
        -L pt_BR -H ${SERVIDOR} \
        -d ${BANCO} \
        -u ${USUARIO} \
        -p ${SENHA} \
        --enable-telemetry --no-interaction

echo "Configuração do Memcached como engine de cache do GLPI."
php /opt/glpi/bin/console glpi:cache:configure --use-default
php /opt/glpi/bin/console glpi:cache:configure --dsn=memcached://192.168.56.11

echo "Alteração da URL padrão do GLPI para glpi.local."
php /opt/glpi/bin/console glpi:config:set url_base 'https://glpi.local'

echo "Remoção do script de backup do GLPI."
rm -rf /opt/glpi/install/install.php

echo "Alteração da senha dos usuários post-only, tech, normal e glpi para 'semsenha'."
mariadb -h ${SERVIDOR} -u${USUARIO} -p${SENHA} ${BANCO} <<- "EOF"
UPDATE glpi_users
SET password='$2y$10$gSOO66tUqpVuhx9ykDtaA.JpsY8QVVXmrVChdWqahutT93XV/aCi2'
WHERE name IN ('post-only', 'tech', 'normal', 'glpi');
EOF

echo "Inserção de entrada CRON para o GLPI."
cat << "EOF" | tee /etc/crontab
* * * * * apache /usr/bin/php -f /opt/glpi/front/cron.php
EOF

echo "Ajustes das permissões das pastas do GLPI, no SELinux."
semanage fcontext -a -t httpd_sys_content_t "/opt/glpi(/.*)?"
semanage fcontext -a -t httpd_sys_content_t "/opt/glpi(/.*)?/\.htaccess"
semanage fcontext -a -t httpd_sys_rw_content_t "/opt/glpi/marketplace(/.*)?"
restorecon -FR /opt/glpi

echo "Ajustes das permissões das pastas de configuração, log e arquivos do GLPI, no SELinux."
semanage fcontext -a -t httpd_sys_rw_content_t "/var/lib/glpi/config(/.*)?"
semanage fcontext -a -t httpd_sys_rw_content_t "/var/lib/glpi/files(/.*)?"
semanage fcontext -a -t httpd_log_t "/var/lib/glpi/log(/.*)?"
restorecon -FR /var/lib/glpi

echo "Ajuste das permissões dos arquivos."
chown -Rf apache. /opt/glpi
find /opt/glpi -type d -exec chmod 755 {} \;
find /opt/glpi -type f -exec chmod 644 {} \;

echo "Ajuste das pastas de configuração, log e arquivos do GLPI."
chown -Rf apache. /var/lib/glpi
find /var/lib/glpi -type d -exec chmod 755 {} \;
find /var/lib/glpi -type f -exec chmod 644 {} \;

echo "Liberação do serviço http, no firewalld."
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --reload

echo "Ativação do serviço Apache."
systemctl enable httpd.service
systemctl start httpd.service

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