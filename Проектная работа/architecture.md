### Архитектура

Архитектурно сотоит из 2х ВМ (виртуальные машины).
1ая ВМ - локальная виртуалка WSL.
На ней установлены CMS Wordpress (php-fpm), Nginx, MySQL и экспортеры сбора метрика с них
node_exporter — метрики самой виртуальной машины (CPU, RAM, disk, network)
nginx_exporter — метрики Nginx (запросы, соединения, коды ответов)
php-fpm-exporter — метрики PHP-FPM (процессы, очереди)
mysqld_exporter — метрики MySQL (запросы, соединения, медленные запросы)
blackbox_exporter — проверка доступности CMS (HTTP-проверки)

Метрики отправляются в Prometheus, к которому подключено хранение в VictoriaMetrics через remote_write
```
# Отправка метрик в VictoriaMetrics
remote_write:
  - url: "http://localhost:8428/api/v1/write"
```

В Prometheus устанволен Alertmanager с настроенными каналами отправки email и Telegram (скрин Проектная работа\screens\alerts_grafana.png).
Конфиг есть в Alertmanager\etc\alertmanager\alertmanager.yml
Можешь взять кусок с отправкой в Telegram для вставки из каталога Alertmanager\etc\alertmanager\alertmanager.yml


Так же на этом сервере установлены filebeat и metricbeat для отправки логов в Logstash на 2ую ВМ и метрик в Elasticsearch.
/etc/filebeat/filebeat.yml
```
# ------------------------------ Logstash Output -------------------------------
output.logstash:
  # The Logstash hosts
  hosts: ["185.254.158.94:5044"]

  # Optional SSL. By default is off.
  # List of root certificates for HTTPS server verifications
  #ssl.certificate_authorities: ["/etc/pki/root/ca.pem"]

  # Certificate for SSL client authentication
  #ssl.certificate: "/etc/pki/client/cert.pem"

  # Client Certificate Key
  #ssl.key: "/etc/pki/client/cert.key"
```

Для filebeat включены модули 
/etc/filebeat/modules.d/mysql.yml
```
- module: mysql
  # Error logs
  error:
    enabled: true

    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    #var.paths:

  # Slow logs
  slowlog:
    enabled: true
```
/etc/filebeat/modules.d/nginx.yml
```
- module: nginx
  # Access logs
  access:
    enabled: true

    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    #var.paths:

  # Error logs
  error:
    enabled: true
```
/etc/metricbeat/metricbeat.yml
```
# ---------------------------- Elasticsearch Output ----------------------------
output.elasticsearch:
  # Array of hosts to connect to.
  hosts: ["https://185.254.158.94:9200"]
  ssl.certificate_authorities: ["/etc/elasticsearch/certs/http_ca.crt"]
  preset: balanced

  username: "elastic"
  password: "dFxxxxxxxxxxxxxxx9UM"
```


Параллельно Grafana Alloy отправляет логи в Grafana Loki на 2ую ВМ.
конфиг alloy
```
// Источник: читаем файлы логов
loki.source.file "logs" {
  targets = [
    // Nginx
    { __path__ = "/var/log/nginx/access.log", job = "nginx" },
    { __path__ = "/var/log/nginx/error.log", job = "nginx" },
    // MySQL
    { __path__ = "/var/log/mysql/error.log", job = "mysql" },
    { __path__ = "/var/log/mysql/mysql-slow.log", job = "mysql-slow" },
    // PHP-FPM
    { __path__ = "/var/log/php8.5-fpm.log", job = "php-fpm" },
  ]
  forward_to = [loki.write.default.receiver]
}

// Назначение: отправляем в Loki
loki.write "default" {
  endpoint {
    url = "http://185.254.158.94:3100/loki/api/v1/push"
  }
```


Еще на 1ой ВМ установлен Zabbix (скрин Проектная работа\screens\zabbix.png) и Grafana, настроены дашборды инфраструкуры и сборный дашборд мониторинга сайта (скрин Проектная работа\screens\grafana_dash.png).
+ в Grafana и Zabbix настроены алерты. В Grafana через канал AlertManager, в Zabbix через Telegram.


2ая удаленная ВМ - 185.254.158.94
На ней установлены Heartbeat (для проверки доступности сайта на 1ой ВМ), Logstash, Elasticsearch + Kibana и Grafana Loki.
Logstash принимает логи от filebeat, проводит обработку и отправляет в Elasticsearch.
```
filter {
  # --- 1. Nginx Access ---
  if [event][dataset] == "nginx.access" {
    grok {
      match => { "message" => "%{IPORHOST:client_ip} - %{USER:ident} \[%{HTTPDATE:timestamp}\] \"%{WORD:method} %{URIPATHPARAM:request_path} HTTP/%{NUMBER:http_version}\" %{NUMBER:status} %{NUMBER:body_bytes_sent} \"%{DATA:referrer}\" \"%{DATA:user_agent}\"" }
    }
    date { match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ] target => "@timestamp" }
    mutate { remove_field => ["message", "timestamp"] }
  }

  # --- 2. Nginx Error ---
  if [event][dataset] == "nginx.error" {
    # Формат: 2026/10/30 05:44:09 [error] 123#123: *1 message
    grok {
      match => { "message" => "%{TIMESTAMP_ISO8601:nginx_timestamp} \[%{LOGLEVEL:level}\] %{NUMBER:pid}#%{NUMBER:tid}: (\*%{NUMBER:connection_id} )?%{GREEDYDATA:error_message}" }
    }
    date { match => [ "nginx_timestamp", "ISO8601" ] target => "@timestamp" }
    mutate { remove_field => ["message", "nginx_timestamp"] }
  }

  # --- 3. MySQL Error ---
  if [event][dataset] == "mysql.error" {
    grok {
      match => { "message" => "%{TIMESTAMP_ISO8601:mysql_timestamp} %{NUMBER:thread_id} \[%{LOGLEVEL:level}\] \[%{DATA:error_code}\] \[%{DATA:subsystem}\] %{GREEDYDATA:error_message}" }
    }
    date { match => [ "mysql_timestamp", "ISO8601" ] target => "@timestamp" }
    mutate { remove_field => ["message", "mysql_timestamp"] }
  }

  # --- 4. MySQL Slowlog ---
  if [event][dataset] == "mysql.slowlog" {
    # Медленные запросы — многострочные. Filebeat обычно уже склеивает их в одно событие.
    # Парсим заголовок: # Time: 2026-10-30T05:44:09.123456Z ... Query_time: 2.5 ...
    grok {
      match => { "message" => "(?m)^# Time: %{TIMESTAMP_ISO8601:slow_timestamp}.*?Query_time: %{NUMBER:query_time}.*?Rows_sent: %{NUMBER:rows_sent}.*?Rows_examined: %{NUMBER:rows_examined}.*?(?:\nSET timestamp=%{NUMBER:unix_timestamp};\n)?(?<query>SELECT.*|UPDATE.*|DELETE.*|INSERT.*|REPLACE.*);?" }
    }
    date { match => [ "slow_timestamp", "ISO8601" ] target => "@timestamp" }
    mutate { remove_field => ["message", "slow_timestamp"] }
  }
}
```

В Kibana настроены Data View на индексы (Проектная работа\screens\kibana_logs.jpg) для логов
```
logstash-nginx-access-*
logstash-mysql-slow-*
logstash-nginx-error-* 
logstash-mysql-error-* 
```

Так же можно посмотреть результат работы heartbeat в Infrastructure - Uptime - Monitor (Проектная работа\screens\uptime_monitor.jpg) для проверки работы Heartbeat
И метрики в Observability - Infrastructure - Overview (Проектная работа\screens\kibana_metrics.jpg)

Kibana 185.254.158.94:5601
Elasticsearch на порту 9200

/etc/loki/loki-config.yaml
Grafana Alloy
```
auth_enabled: false

server:
  http_listen_address: 0.0.0.0
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  instance_addr: 127.0.0.1
  path_prefix: /var/lib/loki
  storage:
    filesystem:
      chunks_directory: /var/lib/loki/chunks
      rules_directory: /var/lib/loki/rules
  replication_factor: 1
  ring:
    kvstore:
      store: inmemory

schema_config:
  configs:
    - from: 2020-10-24
      store: tsdb
      object_store: filesystem
      schema: v13
      index:
        prefix: index_
        period: 24h
```