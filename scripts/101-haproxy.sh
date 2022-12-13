#!/usr/bin/env bash

echo "Instalação do HAProxy"
dnf install -y haproxy

echo "Implantação das configurações do HAProxy para o GLPI"
cat <<EOF | tee /etc/haproxy/haproxy.cfg > /dev/null
global
    log         127.0.0.1 local2

    chroot	/var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group	haproxy
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
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    option                  contstats
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

frontend stats
    bind *:8081
    stats enable
    stats uri /glpi-stats
    stats refresh 10s
    stats show-node
    stats admin if TRUE     
    stats auth admin:admin

frontend glpi-server
    bind *:80
    default_backend glpi-server
   
backend glpi-server
    option httpchk
    http-check expect status 200
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server glpi-server 192.168.56.13:80 check observe layer7
EOF

echo "Liberação do acesso à qualquer porta pelo HAProxy no SELinux"
setsebool -P haproxy_connect_any 1

echo "Liberação do serviço http e da porta 8081 no firewalld"
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=public --add-port=8081/tcp --permanent
firewall-cmd --reload

echo "Ativação do serviço HAProxy"
systemctl enable haproxy.service
systemctl start haproxy.service

echo "OK!"
exit 0