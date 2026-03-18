#!/bin/bash
set -e

REPL_USER='repl'
REPL_PASSWORD='!OtusLinux2018'
BET_DUMP='/vagrant/bet.dmp'
MASTER_SQL='/vagrant/master.sql'

apt update

echo "[MASTER] Скачиваем deb пакет Percona..."
wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb

echo "[MASTER] устанавливаем репозиторий Percona..."
dpkg -i percona-release_latest.generic_all.deb

echo "[MASTER] Включаем репозиторий Percona Server 8.0..."
percona-release setup ps80

apt update

echo "[MASTER] Устанавливаем Percona Server 8.0..."
DEBIAN_FRONTEND=noninteractive apt install -y percona-server-server

echo "[MASTER] Копируем конфиги..."
mkdir -p /etc/my.cnf.d
cp -f /vagrant/conf/master/*.cnf /etc/mysql/mysql.conf.d/

echo "[MASTER] Включаем и запускаем mysql..."
systemctl enable mysql
systemctl restart mysql

echo "[MASTER] Ждём запуск mysqld..."
sleep 10

echo "[MASTER] Проверяем доступ к mysql через sudo..."
sudo mysql -e "SELECT VERSION();"

echo "[MASTER] Создаём базу bet..."
sudo sudo mysql -uroot -e "CREATE DATABASE IF NOT EXISTS bet;"

echo "[MASTER] Загружаем дамп bet.dmp..."
sudo mysql -uroot bet < "${BET_DUMP}"

echo "[MASTER] Создаём пользователя для репликации..."
sudo mysql -uroot -e "CREATE USER IF NOT EXISTS '${REPL_USER}'@'%' IDENTIFIED BY '${REPL_PASSWORD}';"
sudo mysql -uroot -e "GRANT REPLICATION SLAVE ON *.* TO '${REPL_USER}'@'%';"
sudo mysql -uroot -e "FLUSH PRIVILEGES;"

echo "[MASTER] Создаём дамп master.sql без двух таблиц..."
mysqldump \
  --all-databases \
  --triggers \
  --routines \
  --master-data=2 \
  --set-gtid-purged=ON \
  --single-transaction \
  --ignore-table=bet.events_on_demand \
  --ignore-table=bet.v_same_event \
  -uroot -e > "${MASTER_SQL}"

echo "[MASTER] Проверяем server_id..."
sudo mysql -uroot -e "SELECT @@server_id;"

echo "[MASTER] Проверяем GTID..."
sudo mysql -uroot -e "SHOW VARIABLES LIKE 'gtid_mode';"

echo "[MASTER] Проверяем таблицы в bet..."
sudo mysql -uroot -e "USE bet; SHOW TABLES;"

echo "[MASTER] Готово."