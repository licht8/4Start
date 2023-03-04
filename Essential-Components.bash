#!/bin/bash

# Проверяем, запущен ли скрипт от имени root пользователя
if [[ $EUID -ne 0 ]]; then
   echo "Этот скрипт должен быть запущен от имени root пользователя." 
   exit 1
fi

# Обновляем все установленные пакеты
dnf update -y

# Устанавливаем дополнительные утилиты для работы с системой
dnf install -y nano wget curl git

# Настраиваем SSH
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# Настраиваем файрвол
firewall-cmd --add-service=ssh --permanent
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
firewall-cmd --reload

# Устанавливаем EPEL репозиторий
dnf install -y epel-release

# Устанавливаем и настраиваем fail2ban для защиты от атак по SSH
dnf install -y fail2ban
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sed -i 's/^enabled.*/enabled = true/' /etc/fail2ban/jail.local
systemctl start fail2ban
systemctl enable fail2ban

echo "Базовая настройка завершена."
