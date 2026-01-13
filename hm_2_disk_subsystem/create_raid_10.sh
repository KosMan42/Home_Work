#!/bin/bash

# RAID-массив: /dev/md0
# Диски: /dev/sdb /dev/sdc /dev/sdd /dev/sde

echo "🔄 Очистка сигнатур на дисках..."
for disk in /dev/sdb /dev/sdc /dev/sdd /dev/sde;  do
  wipefs -a "$disk"
done

echo "🛠️ Создание RAID 10 массива..."
mdadm --create --verbose /dev/md0 --level=10 --raid-devices=4 /dev/sdb /dev/sdc /dev/sdd /dev/sde

echo "📄 Сохранение конфигурации RAID..."
mdadm --detail --scan >> /etc/mdadm/mdadm.conf

echo "🔁 Обновление initramfs..."
update-initramfs -u

echo "✅ RAID 10 создан. Проверка статуса:"
cat /proc/mdstat
