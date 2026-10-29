## Домашнее задание 9. Opensearch
### Возьмите за основу стенд из занятий по Elastic Stack:

1. Замените filebeat на fluentbit с аналогичной конфигурацией;
2. Замените Logstash на datapreper - он должен принимать данные от fluentbit;
3. Замените Elasticsearch и Kibana на Opensearch и Opensearch Dashboard.

#### fluentbit
Выключаем filebeat
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl status filebeat
○ filebeat.service - Filebeat sends log files to Logstash or directly to Elasticsearch.
     Loaded: loaded (/usr/lib/systemd/system/filebeat.service; enabled; preset: enabled)
     Active: inactive (dead) since Wed 2026-10-28 19:34:48 +04; 16s ago
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl disable filebeat
Removed '/etc/systemd/system/multi-user.target.wants/filebeat.service'.     
```
Устанавливаем fluent-bit
```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo sh -c 'curl https://packages.fluentbit.io/fluentbit.key | gpg --dearmor > /usr/share/keyrings/fluentbit-keyring.gpg'
  % Total    % Received % Xferd  Average Speed  Time    Time    Time   Current
                                 Dload  Upload  Total   Spent   Left   Speed
100   3175 100   3175   0      0   6532      0                              0
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ codename=$(grep -oP '(?<=VERSION_CODENAME=).*' /etc/os-release)
echo "deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/ubuntu/$codename $codename main" | sudo tee /etc/apt/sources.list.d/fluent-bit.list
deb [signed-by=/usr/share/keyrings/fluentbit-keyring.gpg] https://packages.fluentbit.io/ubuntu/resolute resolute main
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt update
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt install fluent-bit -y
Установка:
  fluent-bit

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo vim /etc/fluent-bit/fluent-bit.conf
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl restart fluent-bit
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl enable fluent-bit
```
#### Установка OpenSearch
```
root@user:~# sudo systemctl stop elasticsearch kibana
root@user:~# sudo systemctl disable elasticsearch kibana
Removed /etc/systemd/system/multi-user.target.wants/kibana.service.
Removed /etc/systemd/system/multi-user.target.wants/elasticsearch.service.
```
```
root@user:~# curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch-release.pgp | sudo gpg --dearmor -o /etc/apt/keyrings/opensearch-release-keyring.gpg
root@user:~# sudo chmod 0644 /etc/apt/keyrings/opensearch-release-keyring.gpg
root@user:~# gpg --show-keys --with-fingerprint /etc/apt/keyrings/opensearch-release-keyring.gpg
gpg: directory '/root/.gnupg' created
gpg: keybox '/root/.gnupg/pubring.kbx' created
pub   rsa4096 2025-03-06 [SC]
      A8B2 D9E0 4CD5 1FEF 6AA2  DB53 BA81 D999 8119 1457
uid                      OpenSearch Project <release@opensearch.org>
sub   rsa4096 2025-03-06 [S] [expires: 2027-03-06]

root@user:~# echo "deb [signed-by=/etc/apt/keyrings/opensearch-release-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/3.x/apt stable main" | sudo tee /etc/apt/sources.list.d/opensearch-3.x.list
deb [signed-by=/etc/apt/keyrings/opensearch-release-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/3.x/apt stable main
root@user:~# sudo apt update
root@user:~# sudo env OPENSEARCH_INITIAL_ADMIN_PASSWORD=xxxxxxx04! apt install opensearch -y

root@user:/etc/opensearch# sudo vim /etc/opensearch/opensearch.yml
# ---------------------------------- Network -----------------------------------
#
# Set the bind address to a specific IP (IPv4 or IPv6):
#
network.host: 0.0.0.0
#
# Set a custom port for HTTP:
#
http.port: 9200
...
#node.max_local_storage_nodes: 3 #  заккоментировал
discovery.type: single-node  # добавил параметр

root@user:/etc/opensearch# sudo /usr/share/opensearch/bin/opensearch-plugin remove opensearch-performance-analyzer
-> removing [opensearch-performance-analyzer]...
-> preserving plugin config files [/etc/opensearch/opensearch-performance-analyzer] in case of upgrade; use --purge if not needed



root@user:/etc/opensearch# curl -X GET "https://localhost:9200/_cluster/health?pretty" -ku admin:mypassxxxxxx --insecure
{
  "cluster_name" : "opensearch",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "discovered_master" : true,
  "discovered_cluster_manager" : true,
  "active_primary_shards" : 4,
  "active_shards" : 4,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

#### OpenSearch Dashboards
```
root@user:~# curl -o- https://artifacts.opensearch.org/publickeys/opensearch-release.pgp | sudo gpg --dearmor --batch --yes -o /etc/apt/keyrings/opensearch-release-keyring.gpg
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  3919  100  3919    0     0  21100      0 --:--:-- --:--:-- --:--:-- 21069
root@user:~# sudo chmod 0644 /etc/apt/keyrings/opensearch-release-keyring.gpg
root@user:~# echo "deb [signed-by=/etc/apt/keyrings/opensearch-release-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/3.x/apt stable main" | sudo tee /etc/apt/sources.list.d/opensearch-dashboards-3.x.list
deb [signed-by=/etc/apt/keyrings/opensearch-release-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/3.x/apt stable main
root@user:~# sudo apt update
root@user:~# sudo apt install opensearch-dashboards -y
root@user:~# sudo vim /etc/opensearch-dashboards/opensearch_dashboards.yml
server.port: 5601
server.host: "0.0.0.0"
opensearch.hosts: ["http://localhost:9200"]
opensearch.username: "admin"
opensearch.password: "xxxxxxxxxxx!"
root@user:~# sudo systemctl restart opensearch-dashboards
```
#### DataPreper
```
root@user:~# mkdir -p ~/data-prepper
root@user:~# vim ~/data-prepper/pipelines.yaml
root@user:/tmp# docker pull opensearchproject/data-prepper:latest
root@user:/tmp# docker run --rm -it \
  --name data-prepper \
  -p 2021:2021 \
  -v ~/data-prepper/pipelines.yaml:/usr/share/data-prepper/pipelines/pipelines.yaml \
  --add-host=host.docker.internal:host-gateway \
  opensearchproject/data-prepper:latest
```