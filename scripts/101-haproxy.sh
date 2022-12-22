#!/usr/bin/env bash

echo "Instalação do HAProxy."
dnf install -y haproxy

echo "Criação de certificado autoassinado para o HAProxy."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/haproxy/haproxy-selfsigned.key \
        -out /etc/haproxy/haproxy-selfsigned.crt \
        -subj "/C=BR/ST=Parana/L=Curitiba/O=OverStackFlow/OU=IT/CN=glpi.local"
cat /etc/haproxy/haproxy-selfsigned.key /etc/haproxy/haproxy-selfsigned.crt >> /etc/haproxy/haproxy-selfsigned.pem
chmod 600 /etc/haproxy/haproxy-selfsigned.pem

echo "Implantação das configurações do HAProxy para o GLPI."
mv /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.orig
cat << EOF | tee /etc/haproxy/haproxy.cfg > /dev/null
global
    log         127.0.0.1 local2 info

    chroot	    /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group	    haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

    # utilize system-wide crypto-policies
    ssl-default-bind-ciphers PROFILE=SYSTEM
    ssl-default-server-ciphers PROFILE=SYSTEM

defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option                  http-server-close
    option                  redispatch
    option                  contstats
    retries                 3
    option forwardfor       except 127.0.0.0/8
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend stats
    bind *:8081 ssl crt /etc/haproxy/haproxy-selfsigned.pem ssl-min-ver TLSv1.2
    stats enable
    stats uri /glpi-stats
    stats refresh 10s
    stats show-node
    stats admin if TRUE     
    stats auth admin:admin

frontend glpi-server
    bind *:443 ssl crt /etc/haproxy/haproxy-selfsigned.pem ssl-min-ver TLSv1.2
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Forwarded-Port 443
    default_backend glpi-server
   
backend glpi-server
    option httpchk
    http-send-name-header Host
    http-check expect status 200
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server glpi-server ${SERVIDOR_WEB}:80 check observe layer7
EOF

echo "Liberação do acesso da porta 8081 pelo HAProxy no SELinux."
#setsebool -P haproxy_connect_any 1
semanage port -m -t http_port_t -p tcp 8081

echo "Liberação do serviço https e da porta 8081 no firewalld."
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --permanent --zone=public --add-port=8081/tcp
firewall-cmd --reload

echo "Ativação do serviço HAProxy."
systemctl enable haproxy.service
systemctl start haproxy.service

echo "OK!"
exit 0