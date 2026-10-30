генератор ошибок nginx
добавлен location на порт, который никто не слушает для генерации ошибок
```
less /etc/nginx/sites-available/wordpress
curl http://localhost/generate-error


less /var/log/nginx/error.log

```

mysql генерация медленных запросов и ошибок
```
sudo mysql -u root -p

sudo systemctl restart mysql
less /var/log/mysql/error.log

```