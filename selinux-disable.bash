#!/bin/bash

# Проверяем, запущен ли скрипт с правами root
if [ "$(id -u)" != "0" ]; then
   echo "Этот скрипт должен быть запущен с правами root." 1>&2
   exit 1
fi

# Отключаем SELinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
setenforce 0

# Выводим сообщение об успешном отключении SELinux
echo "SELinux успешно отключен. Пожалуйста, перезагрузите сервер для применения изменений."
