## Домашнее задание 6
### Сконфигурировать heartbeat, filebeat и metricbeat на отправку данных в Elasticsearch:

+ На виртуальной машине установите любую open-source CMS, которая включает в себя следующие компоненты: nginx, php-fpm, database (MySQL или PostgreSQL). Можно взять из предыдущих заданий;
+ На этой же VM установите filebeat и metricbeat. Filebeat должен собирать логи nginx, php-fpm и базы данных. Metricbeat должен собирать метрики VM, nginx, базы данных;
+ Установите на второй VM Elasticsearch и Kibana, а также heartbeat;
Heartbeat должен проверять доступность следующих ресурсов: веб-адрес вашей CMS и порта БД


https://mirror.yandex.ru/mirrors/elastic/9/pool/main/m/filebeats/
https://mirror.yandex.ru/mirrors/elastic/9/pool/main/m/metricbeat/

#### filebeat
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ cd /tmp/
andrew@VLADIMIR-PC:/tmp$ sudo dpkg -i filebeat-9.5.5-amd64.deb
Настраивается пакет filebeat (9.5.5) …
andrew@VLADIMIR-PC:/tmp$ sudo filebeat modules enable nginx mysql system
Enabled nginx
Enabled mysql
Enabled system
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/filebeat/filebeat.yml
# ---------------------------- Elasticsearch Output ----------------------------
output.elasticsearch:
  # Array of hosts to connect to.
  hosts: ["https://185.000.000.224:9200"]
  ssl.certificate_authorities: ["/etc/elasticsearch/certs/http_ca.crt"]
  username: "elastic"
  password: "xxxxxxxxxxxxxxxxxxx"
```

#### metricbeat
```
andrew@VLADIMIR-PC:/tmp$ sudo dpkg -i metricbeat-9.5.5-amd64.deb
andrew@VLADIMIR-PC:/tmp$ sudo metricbeat modules enable system nginx mysql
Module system is already enabled
Enabled nginx
Enabled mysql
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/metricbeat/metricbeat.yml
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/metricbeat/metricbeat.yml
# ---------------------------- Elasticsearch Output ----------------------------
output.elasticsearch:
  # Array of hosts to connect to.
  hosts: ["https://185.000.000.224:9200"]
  ssl.certificate_authorities: ["/etc/elasticsearch/certs/http_ca.crt"]
  username: "elastic"
  password: "xxxxxxxxxxxxxxxxxxx"
```
файл скопировал со 2ой ВМки после установки 
```
andrew@VLADIMIR-PC:/tmp$ sudo scp root@xxx.xxx.xxx.224:/etc/elasticsearch/certs/http_ca.crt /etc/elasticsearch/certs/
```

### 2ая ВМка
#### elasticsearch
```
root@user:~# echo "deb [trusted=yes] https://mirror.yandex.ru/mirrors/elastic/9/ stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list
deb [trusted=yes] https://mirror.yandex.ru/mirrors/elastic/9/ stable main
root@user:~# sudo apt update
W: GPG error: https://mirror.yandex.ru/mirrors/elastic/9 stable InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY D27D666CD88E42B4
root@user:~# wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
File '/usr/share/keyrings/elasticsearch-keyring.gpg' exists. Overwrite? (y/N) y
root@user:~# sudo rm /etc/apt/sources.list.d/elastic-9.x.list
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://mirror.yandex.ru/mirrors/elastic/9/ stable main" | sudo tee /etc/apt/sources.list.d/elastic-9.x.list
deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://mirror.yandex.ru/mirrors/elastic/9/ stable main
root@user:~# sudo apt update
root@user:~# sudo apt install elasticsearch -y
root@user:~# sudo vim /etc/elasticsearch/elasticsearch.yml
network.host: 0.0.0.0
# password reset for file-/metricbeat user/pass
root@user:~# sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u elastic
root@user:~# curl -k -u elastic:xxxxxPASSxxxxxxxxx https://localhost:9200
{
  "name" : "user",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "0SLUZl2tSI2MWlgHAqEnVQ",
  "version" : {
    "number" : "9.5.5",
    "build_flavor" : "default",
    "build_type" : "deb",
    "build_hash" : "48acba663b09e70b115dd879329141506c377890",
    "build_date" : "2026-09-30T22:12:03.984586187Z",
    "build_snapshot" : false,
    "lucene_version" : "10.5.1",
    "minimum_wire_compatibility_version" : "8.19.0",
    "minimum_index_compatibility_version" : "8.0.0"
  },
  "tagline" : "You Know, for Search"
}
```
#### Kibana
```
root@user:~# wget https://mirror.yandex.ru/mirrors/elastic/9/pool/main/k/kibana/kibana-9.5.5-amd64.deb
root@user:~# sudo dpkg -i kibana-9.5.5-amd64.deb

root@user:~# sudo vim /etc/kibana/kibana.yml
server.host: "0.0.0.0"
server.port: 5601
elasticsearch.hosts: ["https://localhost:9200"]
elasticsearch.ssl.certificateAuthorities: ["/etc/elasticsearch/certs/http_ca.crt"]
elasticsearch.username: "kibana_system"

root@user:~# sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system
Password for the [kibana_system] user successfully reset.
New value: xxxxxxxxxxxxxxxxxx
root@user:~# sudo /usr/share/kibana/bin/kibana-keystore create
A Kibana keystore already exists. Overwrite? [y/N] y
Created Kibana keystore in /etc/kibana/kibana.keystore
root@user:~# sudo /usr/share/kibana/bin/kibana-keystore add elasticsearch.password
Enter value for elasticsearch.password: ********************
```
Были ошибки
```
Oct 26 18:36:05 user kibana[3392]:  FATAL  Error: EACCES: permission denied, open '/etc/elasticsearch/certs/http_ca.crt'
Oct 26 18:36:05 user systemd[1]: kibana.service: Main process exited, code=exited, status=1/FAILURE
root@user:~# sudo chmod o+r /etc/elasticsearch/certs/http_ca.crt
```
все равно ошибка, копирую ца серт в кибана
```
root@user:~# ls -la /etc/elasticsearch/certs/http_ca.crt
-rw-rw-r-- 1 root elasticsearch 1935 Oct 26 17:39 /etc/elasticsearch/certs/http_ca.crt
root@user:~# sudo -u kibana cat /etc/elasticsearch/certs/http_ca.crt > /dev/null && echo "READ OK" || echo "READ FAILED"
cat: /etc/elasticsearch/certs/http_ca.crt: Permission denied
READ FAILED
root@user:~# sudo mkdir -p /etc/kibana/certs
root@user:~# sudo cp /etc/elasticsearch/certs/http_ca.crt /etc/kibana/certs/
root@user:~# sudo chmod 644 /etc/kibana/certs/http_ca.crt
root@user:~# sudo -u kibana cat /etc/kibana/certs/http_ca.crt > /dev/null && echo "READ OK" || echo "READ FAILED"
READ OK
root@user:~# sudo vim /etc/kibana/kibana.yml
```

Включаю модули в filebeat (true)
```
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/filebeat/modules.d/system.yml
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/filebeat/modules.d/nginx.yml
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/filebeat/modules.d/mysql.yml
andrew@VLADIMIR-PC:/tmp$ sudo systemctl start filebeat
andrew@VLADIMIR-PC:/tmp$ sudo systemctl enable filebeat
```
И для metricbeat
```
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/metricbeat/modules.d/nginx.yml
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/metricbeat/modules.d/mysql.yml
andrew@VLADIMIR-PC:/tmp$ sudo systemctl start metricbeat
andrew@VLADIMIR-PC:/tmp$ sudo systemctl enable metricbeat
```

#### Heartbeat
```
root@user:~# sudo apt install heartbeat-elastic -y
root@user:~# sudo vim /etc/heartbeat/heartbeat.yml
root@user:~# sudo systemctl start heartbeat-elastic
root@user:~# sudo systemctl enable heartbeat-elastic
root@user:~# sudo systemctl status heartbeat-elastic --no-pager
● heartbeat-elastic.service - Ping remote services for availability and log results to Elasticsearch or send to Logstash.
     Loaded: loaded (/lib/systemd/system/heartbeat-elastic.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2026-10-26 19:41:46 UTC; 32s ago

root@user:~# sudo heartbeat setup -e
```