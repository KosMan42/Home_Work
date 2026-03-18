#!/bin/bash
set -e

REPL_USER='repl'
REPL_PASSWORD='!OtusLinux2018'
MASTER_HOST='192.168.11.150'
MASTER_SQL='/vagrant/master.sql'

apt update

echo "[SLAVE] Скачиваем deb пакет Percona..."
wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb

echo "[SLAVE] устанавливаем репозиторий Percona..."
dpkg -i percona-release_latest.generic_all.deb

echo "[SLAVE] Включаем репозиторий Percona Server 8.0..."
percona-release setup ps80

apt update

echo "[SLAVE] Устанавливаем Percona Server 8.0..."
DEBIAN_FRONTEND=noninteractive apt install -y percona-server-server

echo "[SLAVE] Копируем конфиги..."
mkdir -p /etc/my.cnf.d
cp -f /vagrant/conf/slave/*.cnf /etc/mysql/mysql.conf.d/

echo "[SLAVE] Включаем и запускаем mysql..."
systemctl enable mysql
systemctl restart mysql

echo "[SLAVE] Ждём запуск mysqld..."
sleep 10

echo "[SLAVE] Ждём появления /vagrant/master.sql..."
for i in {1..60}; do
  if [ -f "${MASTER_SQL}" ]; then
    echo "[SLAVE] Файл master.sql найден."
    break
  fi
  echo "[SLAVE] master.sql ещё не готов, ждём 5 сек..."
  sleep 5
done

if [ ! -f "${MASTER_SQL}" ]; then
  echo "[SLAVE] Ошибка: master.sql не найден."
  exit 1
fi

echo "[SLAVE] Заливаем master.sql..."
sudo mysql -uroot < "${MASTER_SQL}"

echo "[SLAVE] Настраиваем репликацию..."
sudo mysql -uroot -e "STOP REPLICA; RESET REPLICA ALL;" || true

sudo mysql -uroot -e "
CHANGE REPLICATION SOURCE TO
  MASTER_HOST='${MASTER_HOST}',
  MASTER_PORT=3306,
  MASTER_USER='${REPL_USER}',
  MASTER_PASSWORD='${REPL_PASSWORD}',
  MASTER_AUTO_POSITION=1,
  GET_SOURCE_PUBLIC_KEY=1;
"

echo "[SLAVE] Запускаем slave..."
sudo mysql -uroot -e "START REPLICA;"

echo "[SLAVE] Проверяем server_id..."
sudo mysql -uroot -e "SELECT @@server_id;"

echo "[SLAVE] Проверяем GTID..."
sudo mysql -uroot -e "SHOW VARIABLES LIKE 'gtid_mode';"

echo "[SLAVE] Проверяем таблицы в bet..."
sudo mysql -uroot -e "USE bet; SHOW TABLES;"

echo "[SLAVE] Статус репликации:"
sudo mysql -uroot -e "SHOW REPLICA STATUS\G"

echo "[SLAVE] Готово."