# Observability 2026


напиши мне проект для презентации Проектной работы по этому обучению.
Тема  Разработка комплексной системы мониторинга и логирования веб-инфраструктуры на базе стека VictoriaMetrics, Grafana, Zabbix и Elasticsearch (OpenSearch)»

Напиши назначение, тему, что ее сделал Хахулин Адрей Игоревич - SRE Engineer.

Ее архитектура - 2 ВМ (виртуальные машины).
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

В Prometheus устанволен Alertmanager с настроенными каналами отправки email и Telegram.

Так же на этом сервере установлены filebeat и metricbeat для отправки логов в Logstash на 2ую ВМ и метрик в Elasticsearch.
Параллельно Grafana Alloy отправляет логи в Grafana Loki на 2ую ВМ.

Еще на 1ой ВМ установлен Zabbix и Grafana, настроены дашборды инфраструкуры и сборный дашборд мониторинга сайта.
+ в Grafana и Zabbix настроены алерты. В Grafana через канал AlertManager, в Zabbix через Telegram.


2ая удаленная ВМ - 185.254.158.94
На ней установлены Heartbeat для проверки доступности сайта на 1ой ВМ, Logstash, Elasticsearch + Kibana , Grafana Loki.
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

В Kibana настроены Data View на индексы (есть скрин для вставки в презентацию) для логов
logstash-nginx-access-*
logstash-mysql-slow-*
logstash-nginx-error-* 
logstash-mysql-error-* 

Так же можно посомтреть Infrastructure - Uptime - Monitor (есть скрин для вставки в презентацию) для проверки работы Heartbeat
И метрики в Observability - Infrastructure - Overview

Kibana 185.254.158.94:5601
Elasticsearch на порту 9200


