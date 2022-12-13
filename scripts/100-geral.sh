#!/usr/bin/env bash

echo "Atualização do sistema"
dnf update -y

echo "Instalação de bibliotecas de linguagem pt_BR e configurações de localidade"
dnf install -y nano glibc-langpack-pt
localectl set-locale LANG=pt_BR.utf8
localectl set-locale LC_TIME=pt_BR.utf8
localectl set-locale LC_CTYPE=pt_BR.utf8
localectl set-locale LC_NUMERIC=pt_BR.utf8

echo "Ajuste do timezone"
timedatectl set-timezone America/Sao_Paulo

echo "Instalação do Cockpit"
dnf install -y cockpit

echo "Ativação do serviço Cockpit"
sudo systemctl enable cockpit.socket
sudo systemctl start cockpit.socket

echo "OK!"
exit 0