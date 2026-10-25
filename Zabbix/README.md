## Домашнее задание 5
### LLD и оповещения Zabbix

### Цель:
+ установить и настроить zabbix;
+ реализовать автоматическое обнаружение метрик и отправку уведомлений при превышении пороговых значений.

```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu26.04_all.deb
--2026-10-25 13:02:47--  https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu26.04_all.deb
Распознаётся repo.zabbix.com (repo.zabbix.com)… 178.128.6.101, 2604:a880:2:d0::2062:d001
Подключение к repo.zabbix.com (repo.zabbix.com)|178.128.6.101|:443... соединение установлено.
HTTP-запрос отправлен. Ожидание ответа… 200 OK
Длина: 7984 (7,8K) [application/octet-stream]
Сохранение в: ‘zabbix-release_latest_7.4+ubuntu26.04_all.deb’

zabbix-release_latest_7.4+ubu 100%[=================================================>]   7,80K  --.-KB/s    за 0,001s

2026-10-25 13:02:47 (9,68 MB/s) - ‘zabbix-release_latest_7.4+ubuntu26.04_all.deb’ сохранён [7984/7984]

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo dpkg -i zabbix-release_latest_7.4+ubuntu26.04_all.deb
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt update
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent
Установка:
  zabbix-agent  zabbix-nginx-conf  zabbix-frontend-php  zabbix-server-mysql  zabbix-sql-scripts
```

#### Создание БД
```
sudo mysql -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
sudo mysql -e "create user zabbix@localhost identified by 'xxxxxx004';"
sudo mysql -e "grant all privileges on zabbix.* to zabbix@localhost;"
sudo mysql -e "set global log_bin_trust_function_creators = 1;"
sudo zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p'xxxxxx004' zabbix
sudo mysql -e "set global log_bin_trust_function_creators = 0;"
```

#### nginx
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo vim /etc/zabbix/nginx
server {
        listen          8081;
        server_name     localhost;

sudo ln -s /etc/zabbix/nginx.conf /etc/nginx/sites-enabled/zabbix.conf
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo nginx -t
2026/10/25 13:35:16 [warn] 33770#33770: conflicting server name "localhost" on 0.0.0.0:8081, ignored
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo nginx -T | grep -n -B2 -A2 "listen.*8081"
2026/10/25 13:50:19 [warn] 34158#34158: conflicting server name "localhost" on 0.0.0.0:8081, ignored
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
190-# configuration file /etc/nginx/conf.d/zabbix.conf:
191-server {
192:        listen          8081;
193-        server_name     localhost;
194-
--
373-# configuration file /etc/nginx/sites-enabled/zabbix.conf:
374-server {
375:        listen          8081;
376-        server_name     localhost;
377-

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo rm /etc/nginx/sites-enabled/zabbix.conf
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo nginx -T | grep -n -B2 -A2 "listen.*8081"
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
190-# configuration file /etc/nginx/conf.d/zabbix.conf:
191-server {
192:        listen          8081;
193-        server_name     localhost;
194-
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl reload nginx
```

#### Генератор
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo vim /usr/local/bin/otus_metrics.sh
#!/bin/bash
case "$1" in
    "discovery")
        echo '{
            "data": [
                {"{#METRIC}": "metric1"},
                {"{#METRIC}": "metric2"},
                {"{#METRIC}": "metric3"}
            ]
        }'
        ;;
    "metric1"|"metric2"|"metric3")
        echo $((RANDOM % 101))
        ;;
esac

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo chmod +x /usr/local/bin/otus_metrics.sh
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ vim /etc/zabbix/zabbix_agentd.conf
UserParameter=otus.discovery,/usr/local/bin/otus_metrics.sh discovery
UserParameter=otus.metric[*],/usr/local/bin/otus_metrics.sh $1

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl status zabbix-agent.service
```