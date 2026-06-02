 Установил  NGINX, PHP  
 ```
 andrew@VLADIMIR-PC:/mnt/c/Users/97976/Downloads$ sudo apt install nginx php-fpm php-pgsql php-mysql php-gd php-curl php-xml php-zip php-mbstring -y  
 ```

Установил PostgreSQL
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976/Downloads$ sudo -i -u postgres
```

Пробовал настроить с postgreSQL, но не поднимался CMS Wordpress, потому что Wordpress для работы с PostgreSQL нужен был какой то доп плагин, но у меня и с ним была ошибка при старте CMS

```
andrew@VLADIMIR-PC:/mnt/c/Users/97976/Downloads$ cd /tmp/  
andrew@VLADIMIR-PC:/tmp$ wget https://ru.wordpress.org/latest-ru_RU.tar.gz  
andrew@VLADIMIR-PC:/tmp$ tar -xzvf latest-ru_RU.tar.gz  
andrew@VLADIMIR-PC:/tmp$ sudo cp -r /tmp/wordpress/* /var/www/html/  
andrew@VLADIMIR-PC:/var/www/html$ sudo wget https://downloads.wordpress.org/plugin/postgresql-for-wordpress.1.3.1.zip  
andrew@VLADIMIR-PC:/var/www/html$ sudo unzip postgresql-for-wordpress.1.3.1.zip  
andrew@VLADIMIR-PC:/var/www/html$ sudo mkdir -p wp-content/plugins  
andrew@VLADIMIR-PC:/var/www/html$ sudo mv postgresql-for-wordpress/pg4wp wp-content/plugins/  
andrew@VLADIMIR-PC:/var/www/html$ sudo cp wp-content/plugins/pg4wp/db.php wp-content/  
andrew@VLADIMIR-PC:/var/www/html$ sudo nano /var/www/html/wp-config.php  
```

Поэтому я установил MySQL и создал БД и юзера  
```
andrew@VLADIMIR-PC:/var/www/html/wp-content/plugins$ sudo apt install mysql-server -y  
andrew@VLADIMIR-PC:/var/www/html/wp-content/plugins$ sudo mysql << EOF  
CREATE DATABASE cms_database;  
CREATE USER 'cms_user'@'localhost' IDENTIFIED BY 'xxxxxx';  
GRANT ALL PRIVILEGES ON cms_database.* TO 'cms_user'@'localhost';  
FLUSH PRIVILEGES;  
EOF  
```
Потом установил экспортеры:  
* node_exporter — метрики самой виртуальной машины (CPU, RAM, disk, network)  
* nginx_exporter — метрики Nginx (запросы, соединения, коды ответов)  
* php-fpm-exporter — метрики PHP-FPM (процессы, очереди)  
* mysqld_exporter — метрики MySQL (запросы, соединения, медленные запросы)  
* blackbox_exporter — проверка доступности CMS (HTTP-проверки)  

скачивал их wget в /tmp, распаковывал и 
перекидывал их бинарники в /usr/local/bin и создавал службы в 
/etc/systemd/system/node_exporter.service - пример

------------------------

Для работы php-fpm-exporter
Включил /status в Wordpress в  
```
sudo nano /etc/php/8.5/fpm/pool.d/www.conf  
расскоментировал  
pm.status_path = /status  
ping.path = /ping
```

и в сервисе   
```
ExecStart=/usr/local/bin/php_fpm_exporter --phpfpm.scrape-uri "http://localhost/status" 
```

Так же добавил /status в локейшены  
sudo nano /etc/nginx/sites-available/wordpress
```
location /status {
    fastcgi_pass unix:/var/run/php/php8.5-fpm.sock;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    allow 127.0.0.1;
    deny all;
}
```
и рестартанул nginx  - см. скрин status.png

---------------------------

blackbox exporter без сложностей - см /etc/blackbox_exporter/blackbox.yml

------------------------------

nginx_exporter
создал /etc/nginx/sites-available/metrics -см конфиги

-----------------------------

Установка Prometheus
```
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir /etc/prometheus
```

скачал прометеус, распаковал, скопировал 
```
sudo cp prometheus /usr/local/bin/
sudo cp promtool /usr/local/bin/
создал файл конфигурации
/etc/prometheus/prometheus.yml
```

создал сервис, запустил, проверил 
http://localhost:9090 - см. скрин 