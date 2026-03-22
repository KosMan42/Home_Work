# Домашнее задание: Настройка центрального сервера для сбора логов

## Окружение

Работа выполнена на виртуальных машинах:

- Vagrant 2.4.9
- VirtualBox 7.2.6a
- Базовый образ: ubuntu/jammy64

Развертывание выполнено с использованием **Vagrant provisioning (shell-скрипты)**.

---

## Цель работы

В рамках задания реализованы:

1. Поднятие двух виртуальных машин — **web** и **log**
2. Установка и настройка **nginx** на web-сервере
3. Настройка центрального лог-сервера на базе **rsyslog**
4. Отправка логов nginx с web-сервера на log-сервер

---

## Архитектура

| Машина | IP | Роль |
|---|---|---|
| web | 192.168.56.10 | nginx + rsyslog-клиент |
| log | 192.168.56.15 | rsyslog-сервер |

Логи передаются по **TCP 514**.

---

## Развертывание

Стенд разворачивается автоматически через `Vagrantfile`.

Запуск:

```bash
vagrant up
```

Provisioning выполняет:

- синхронизацию времени через `timedatectl`
- установку и настройку rsyslog на log-сервере
- установку nginx на web-сервере
- настройку отправки логов nginx на log-сервер

---

## 1. Настройка log-сервера

На машине **log** настроен rsyslog для приёма логов по TCP и UDP порт 514.

В `/etc/rsyslog.conf` раскомментированы строки:

```
module(load="imudp")
input(type="imudp" port="514")

module(load="imtcp")
input(type="imtcp" port="514")
```

В конец файла добавлены правила сохранения логов от удалённых хостов:

```
#Add remote logs
$template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& stop
```

Логи от каждого хоста сохраняются в отдельную папку. Например, access-логи nginx с сервера web попадают в файл:

```
/var/log/rsyslog/web/nginx_access.log
```

---

## 2. Настройка web-сервера

На машине **web** установлен nginx.

Создан файл `/etc/nginx/conf.d/logging.conf`:

```nginx
error_log /var/log/nginx/error.log;
error_log syslog:server=192.168.56.15:514,tag=nginx_error;
access_log syslog:server=192.168.56.15:514,tag=nginx_access,severity=info combined;
```

Это настраивает nginx на отправку логов одновременно локально и на log-сервер.

---

## Проверка работы

### Генерация access-лога

Обращаемся к nginx с хост-машины или с web:

```bash
curl http://192.168.56.10
```

### Генерация error-лога

Обращаемся к несуществующей странице:

```bash
curl http://192.168.56.10/notfound
```

### Проверка на log-сервере

```bash
ls /var/log/rsyslog/web/
cat /var/log/rsyslog/web/nginx_access.log
cat /var/log/rsyslog/web/nginx_error.log
```

---

## Итог

- Развертывание выполнено автоматически через Vagrant
- Настроен центральный лог-сервер на базе rsyslog
- Логи nginx (access и error) отправляются на удалённый сервер
- Логи хранятся в `/var/log/rsyslog/<hostname>/<programname>.log`
- Работа логирования успешно проверена
