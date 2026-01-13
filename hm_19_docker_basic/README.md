# Custom Nginx Docker Image

Кастомный Docker-образ nginx на базе alpine.
После запуска контейнер отдаёт изменённую стартовую страницу.

## Сборка образа
docker build -t my-nginx:1.0 .

## Запуск контейнера
docker run -d -p 8080:80 my-nginx:1.0
