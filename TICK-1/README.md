```
# Добавляем ключ и репозиторий (для Ubuntu)
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ curl --silent --location -O https://repos.influxdata.com/influxdata-archive.key

gpg --show-keys --with-fingerprint --with-colons ./influxdata-archive.key 2>&1 \
| grep -q '^fpr:\+24C975CBA61A024EE1B631787C3D57159FC2F927:$' \
&& cat influxdata-archive.key \
| gpg --dearmor \
| sudo tee /etc/apt/keyrings/influxdata-archive.gpg > /dev/null

# подключаем репозиторий
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ echo 'deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
deb [signed-by=/etc/apt/keyrings/influxdata-archive.gpg] https://repos.influxdata.com/debian stable main

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt update
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt install influxdb kapacitor chronograf telegraf -y
Установка:
  chronograf  influxdb  kapacitor  telegraf

Установка зависимостей:
  influxdata-archive-keyring

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl start influxdb kapacitor chronograf telegraf
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl enable influxdb kapacitor chronograf telegraf
```
Не работал только telegraf, потому что все [outputs.] были закомментированы
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo journalctl -u telegraf -n 50 --no-pager
окт 25 16:02:31 VLADIMIR-PC telegraf[37945]: 2026-10-25T12:02:31Z I! Loading config: /etc/telegraf/telegraf.conf
окт 25 16:02:31 VLADIMIR-PC telegraf[37945]: 2026-10-25T12:02:31Z E! [telegraf] Error running agent: no outputs found, probably invalid config file provided
кт 25 16:02:33 VLADIMIR-PC systemd[1]: telegraf.service: Failed with result 'exit-code'.
окт 25 16:02:33 VLADIMIR-PC systemd[1]: Failed to start telegraf.service - Telegraf.

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo vim /etc/telegraf/telegraf.conf
[[outputs.influxdb]]
  urls = ["http://127.0.0.1:8086"]
  database = "telegraf"

sudo systemctl restart telegraf
sudo systemctl status telegraf --no-pager

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ influx -execute 'SHOW MEASUREMENTS' -database telegraf
name: measurements
name
----
cpu
disk
diskio
kernel
mem
processes
swap
system


andrew@VLADIMIR-PC:/mnt/c/Users/97976$ influx -execute 'SELECT * FROM cpu LIMIT 5' -database telegraf
name: cpu
time                cpu       host        usage_guest usage_guest_nice usage_idle        usage_iowait        usage_irq usage_nice usage_softirq       usage_steal usage_system        usage_user
----                ---       ----        ----------- ---------------- ----------        ------------        --------- ---------- -------------       ----------- ------------        ----------
1792930510000000000 cpu-total VLADIMIR-PC 0           0                98.6376932720395  0.5766819891350506  0         0          0.05850396991224119 0           0.3259506895110784  0.4011700793982796
1792930510000000000 cpu0      VLADIMIR-PC 0           0                96.38554216870506 2.710843373494031   0         0          0.4016064257029092  0           0.30120481927714626 0.20080321285138328
1792930510000000000 cpu1      VLADIMIR-PC 0           0                97.99799799799104 0.7007007007010891  0         0          0.1001001001000997  0           0.5005005005003919  0.7007007007006624
1792930510000000000 cpu10     VLADIMIR-PC 0           0                99.1967871486133  0                   0         0          0                   0           0.4016064257029092  0.4016064257029092
1792930510000000000 cpu11     VLADIMIR-PC 0           0                98.8933601609602  0.40241448692142634 0         0          0                   0           0.20120724346074892 0.5030181086517651
```

```
sudo mysql -e "CREATE USER 'telegraf'@'localhost' IDENTIFIED BY 'xxxxxx004';"
sudo mysql -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'telegraf'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"
```
add configs in telegraf.conf
```
# Nginx (stub_status)
[[inputs.nginx]]
  urls = ["http://localhost:8080/stub_status"]

# PHP-FPM (status)
[[inputs.phpfpm]]
  urls = ["http://localhost/status"]

# MySQL
[[inputs.mysql]]
  servers = ["telegraf:password@tcp(127.0.0.1:3306)/"]\
```
Теперь есть nginx, php, mysql
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ influx -execute 'SHOW MEASUREMENTS' -database telegraf
name: measurements
name
----
cpu
disk
diskio
kernel
mem
mysql
nginx
phpfpm
processes
swap
system
```
Далее создание дашборда и алертов.
Для алертов по 5хх ошибкам нужен либо nginx-vts модуль, который надо скомпилировать - возникли проблемы из-за версии nginx. Поэтому пошел по пути парсинга access.log:
```
[[inputs.tail]]
  files = ["/var/log/nginx/access.log"]
  name_override = "nginx_access"
  data_format = "value"
  data_type = "string"
  initial_read_offset = "saved-or-beginning"

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo usermod -aG adm telegraf
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl restart telegraf
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo -u telegraf cat /var/log/nginx/access.log | head -1
127.0.0.1 - - [25/Oct/2026:12:47:59 +0400] "GET /stub_status HTTP/1.1" 200 106 "-" "NGINX-Prometheus-Exporter/v1.5.0"
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ influx -execute 'SHOW MEASUREMENTS' -database telegraf | grep nginx_access
nginx_access
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ influx -execute 'SELECT * FROM "nginx_access" LIMIT 5' -database telegraf
name: nginx_access
time                agent                            auth client_ip host        http_version ident path                      referrer request      resp_bytes resp_code verb
----                -----                            ---- --------- ----        ------------ ----- ----                      -------- -------      ---------- --------- ----
1792918079000000000 NGINX-Prometheus-Exporter/v1.5.0 -    127.0.0.1 VLADIMIR-PC 1.1          -     /var/log/nginx/access.log -        /stub_status 106        200       GET
1792918080000000000 Blackbox Exporter/0.27.0         -    127.0.0.1 VLADIMIR-PC 1.1          -     /var/log/nginx/access.log -        /            70094      200       GET
1792918084000000000 NGINX-Prometheus-Exporter/v1.5.0 -    127.0.0.1 VLADIMIR-PC 1.1          -     /var/log/nginx/access.log -        /stub_status 106        200       GET
1792918085000000000 Blackbox Exporter/0.27.0         -    127.0.0.1 VLADIMIR-PC 1.1          -     /var/log/nginx/access.log -        /            70094      200       GET
1792918089000000000 NGINX-Prometheus-Exporter/v1.5.0 -    127.0.0.1 VLADIMIR-PC 1.1          -     /var/log/nginx/access.log -        /stub_status 106        200       GET
```
Но в настройке алерта не было resp_code В поле Field, потому что это тег.
Сделал TICKscript
```
stream
  |from()
    .measurement('nginx_access')
    .where(lambda: "resp_code" =~ /5\d\d/)
  |window()
    .period(5m)
    .every(1m)
  |count('resp_code')
  |alert()
    .crit(lambda: "count" > 0)
    .message('Обнаружены 5xx ошибки: {{ index .Fields "count" }} за последние 5 минут')
    .telegram()
```