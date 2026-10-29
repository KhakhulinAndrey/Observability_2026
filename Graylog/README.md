## Домашнее задание 10. Graylog
### Сконфигурировать Graylog и отправку логов в него

1. На виртуальной машине установите любую open-source CMS, которая включает в себя следующие компоненты: nginx, php-fpm, database (MySQL или PostgreSQL). Можно взять из предыдущих заданий.
2. На этой же VM установите Graylog Sidecar.
3. Установите на второй VM Graylog (server, OpenSearch, MongoDB) и datapreper
4. Подключите установленный Sidecar к Graylog и настройте сбор и отправку логов nginx, php-fpm и базы данных, используя Sidecar.
5. Разделите логи в разные стримы.

###  Вторая ВМ — Установка Graylog Server (OpenSearch + MongoDB)
#### Установика Java и MongoDB
```
root@user:~# sudo apt update
root@user:~# sudo apt install -y openjdk-17-jre-headless gnupg curl
root@user:~# curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
root@user:~# echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse
root@user:~# sudo apt update
root@user:~# sudo apt install -y mongodb-org
root@user:~# sudo systemctl enable --now mongod
Created symlink /etc/systemd/system/multi-user.target.wants/mongod.service → /lib/systemd/system/mongod.service.

root@user:~# mongod --version
db version v7.0.45
Build Info: {
    "version": "7.0.45",
    "gitVersion": "a52313e13ab55c9bddf7c3ff91dab286fa381796",
    "openSSLVersion": "OpenSSL 3.0.2 15 Mar 2022",
    "modules": [],
    "allocator": "tcmalloc",
    "environment": {
        "distmod": "ubuntu2204",
        "distarch": "x86_64",
        "target_arch": "x86_64"
    }
}
```
#### Тест mongodb
```
root@user:~# mongosh
Current Mongosh Log ID: 6ae329e361ae455b49e1f7b2
Connecting to:          mongodb://127.0.0.1:27017/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.14.0
Using MongoDB:          7.0.45
Using Mongosh:          2.14.0

test> db.runCommand({ ping: 1 })
{ ok: 1 }
```
#### Установка Graylog Server
```
root@user:~# wget https://packages.graylog2.org/repo/packages/graylog-7.2-repository_latest.deb
graylog-7.2-repository_latest 100%[=================================================>]   2.03K  --.-KB/s    in 0s

2026-10-29 11:12:51 (64.9 MB/s) - ‘graylog-7.2-repository_latest.deb’ saved [2080/2080]
root@user:~# sudo dpkg -i graylog-7.2-repository_latest.deb
root@user:~# sudo apt update

root@user:~# pwgen -N 1 -s 96  # Это password_secret
g7KMxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxP7p
root@user:~#
root@user:~#
root@user:~# echo -n "Civic117004!" | sha256sum | cut -d " " -f1   # Это root_password_sha2
8b5xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx78

root@user:~# sudo vim /etc/graylog/server/server.conf
password_secret = password_secret
root_password_sha2 = root_password_sha2
http_bind_address = 0.0.0.0:9000
elasticsearch_hosts = https://admin:xxxxxxxxxx@localhost:9200

root@user:~# sudo systemctl enable --now graylog-server
Created symlink /etc/systemd/system/multi-user.target.wants/graylog-server.service → /lib/systemd/system/graylog-server.service.
```
Ошибки
```
root@user:~# sudo tail -n 50 /var/log/graylog-server/server.log
2026-10-29T11:41:07.591Z ERROR [VersionProbe] Unable to retrieve version from indexer node: (certificate_unknown) Certificate chain validation failed for server trust. Tried 1 trust manager(s), all rejected the certificate. Certificate details

root@user:~# sudo find / -name cacerts 2>/dev/null
/usr/share/opensearch/jdk/lib/security/cacerts
/usr/share/elasticsearch/jdk/lib/security/cacerts
/usr/share/logstash/jdk/lib/security/cacerts
/usr/share/graylog-server/jvm/lib/security/cacerts

root@user:~# sudo find /etc/opensearch -name "*.pem" -o -name "*.crt" 2>/dev/null
/etc/opensearch/kirk-key.pem
/etc/opensearch/kirk.pem
/etc/opensearch/esnode.pem
/etc/opensearch/esnode-key.pem
/etc/opensearch/root-ca.pem
root@user:~# sudo keytool -import -alias opensearch-root-ca -keystore /usr/share/graylog-server/jvm/lib/security/cacerts -file /etc/opensearch/root-ca.pem
Certificate was added to keystore
root@user:~# sudo keytool -import -alias opensearch-node -keystore /usr/share/graylog-server/jvm/lib/security/cacerts -file /etc/opensearch/esnode.pem
```
#### Настройка в Graylog (Input, Token, Sidecar Config)
1. В UI создал Beats Input
2. Создал API Token для Sidecars: System → Sidecars - Create or reuse a token
3. Создал конфигурацию коллектора (Filebeat). Sidecars - Configuration - Create Configuration
Collector: Filebeat on Linux
Теги: otus, o11y, cms_logs

### Первая ВМ — Установка и настройка Sidecar
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl stop fluent-bit
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl disable fluent-bit

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ wget https://packages.graylog2.org/repo/packages/graylog-sidecar-repository_1-5_all.deb
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo dpkg -i graylog-sidecar-repository_1-5_all.deb
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt update
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt install -y graylog-sidecar
Установка:
  graylog-sidecar

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo vim /etc/graylog/sidecar/sidecar.yml

server_url: "http://000.000.000.94:9000/api/"
server_api_token: "85xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxb2"
node_name: "cms-vm-otus"
tags:
  - otus
  - linux
```

Во вложении конфиг graylog-sidecar - filebeat.conf (Sidecar Configuration в Graylog)
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo less /var/lib/graylog-sidecar/generated/6ae339b55d156239517b954e/filebeat.co
nf
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo ps aux | grep filebeat | grep -v grep
root       30358  0.1  1.0 2555164 80996 ?       Sl   17:39   0:01 /usr/lib/graylog-sidecar/filebeat -c /var/lib/graylog-sidecar/generated/6ae339b55d156239517b954e/filebeat.conf
```