#!/bin/bash

# Проверяем, запущен ли скрипт с правами root
if [ "$(id -u)" != "0" ]; then
   echo "Этот скрипт должен быть запущен с правами root." 1>&2
   exit 1
fi

# Добавляем репозиторий Webmin
cat << EOF > /etc/yum.repos.d/webmin.repo
[Webmin]
name=Webmin Distribution Neutral
#baseurl=https://download.webmin.com/download/yum
mirrorlist=https://download.webmin.com/download/yum/mirrorlist
enabled=1
EOF

# Устанавливаем GPG-ключ Webmin
rpm --import http://www.webmin.com/jcameron-key.asc

# Устанавливаем Webmin
yum install -y webmin

# Разрешаем доступ к Webmin с помощью брандмауэра firewalld
firewall-cmd --zone=public --add-port=10000/tcp --permanent
firewall-cmd --reload

# Выводим сообщение об успешной установке
echo "Webmin успешно установлен и настроен. Откройте браузер и перейдите по адресу https://<IP_адрес_сервера>:10000 для доступа к панели управления."
