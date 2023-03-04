#!/bin/bash

# Обновляем все пакеты на сервере
yum update -y

# Устанавливаем необходимые пакеты
yum install -y epel-release
yum install -y wireguard-tools qrencode

# Генерируем ключи для сервера
umask 077
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key

# Создаем конфигурационный файл для WireGuard сервера
read -p "Введите IP адрес для сервера: " server_ip
read -p "Введите порт для WireGuard сервера (по умолчанию 51820): " server_port
read -p "Введите IP адрес сети WireGuard: " wg_ip
read -p "Введите маску сети WireGuard (по умолчанию 24): " wg_mask
cat << EOF > /etc/wireguard/wg0.conf
[Interface]
PrivateKey = $(cat /etc/wireguard/server_private.key)
Address = $wg_ip/$wg_mask
ListenPort = $server_port

[Peer]
PublicKey = $(cat /etc/wireguard/client_public.key)
AllowedIPs = $wg_ip/32
EOF

# Генерируем ключи для клиента
umask 077
wg genkey | tee /etc/wireguard/client_private.key | wg pubkey > /etc/wireguard/client_public.key

# Создаем конфигурационный файл для WireGuard клиента
cat << EOF > /etc/wireguard/wg0-client.conf
[Interface]
PrivateKey = $(cat /etc/wireguard/client_private.key)
Address = $wg_ip/32

[Peer]
PublicKey = $(cat /etc/wireguard/server_public.key)
Endpoint = $server_ip:$server_port
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 15
EOF

# Настройка WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Генерируем QR код для конфигурации клиента
qrencode -t ansiutf8 < /etc/wireguard/wg0-client.conf

# Выводим информацию о системе
echo "WireGuard успешно установлен и настроен."
echo "QR код для конфигурации клиента:"
qrencode -t ansiutf8 < /etc/wireguard/wg0-client.conf

exit 0
