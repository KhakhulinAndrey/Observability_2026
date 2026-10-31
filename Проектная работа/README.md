

systemctl | grep exporter


Метрики идут в прометеус, у которого подключено хранение в victoriametrics
vim /etc/prometheus/prometheus.yml


systemctl | grep beat


filebeat - logstash - elasticsearch
metricbeat - elasticsearch


Индесы logstash
vim /etc/logstash/conf.d/nginx-parse.conf

heartbeat
vim /etc/heartbeat/heartbeat.yml

конфиг Alloy
sudo vim /etc/alloy/config.alloy

Конфиг Grafana Loki - не показывай
sudo vim /etc/loki/loki-config.yaml

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
sudo journalctl -u logstash -n 50 --no-pager
sudo journalctl -u logstash -n 50 --no-pager

sudo journalctl -u logstash -n 100 --no-pager
less /var/log/logstash/logstash-plain.log