## Домашнее задание 6
### Используйте тот же стенд из 2-х VM, как в предыдущем задании::

+ Установите Logstash на виртуальную машину с Elasticsearch. Перенастройте отправку логов в него. В Logstash добавьте парсинг логов при помощи grok-фильтра (Filebeat пусть при этом шлет сырые данные).
+ Вместо Logstash установите и настройте Vector с аналогичным парсингом логов при помощи VRL.

####  Установка Logstash
```
root@user:~# sudo apt update
root@user:~# sudo apt install logstash -y
root@user:~# vim /etc/logstash/conf.d/nginx-parse.conf
root@user:~# sudo systemctl restart logstash
```

#### Vector
```
sudo systemctl stop logstash
sudo systemctl disable logstash
curl --proto '=https' --tlsv1.2 -sSfL https://sh.vector.dev | bash
                                   __   __  __
                                   \ \ / / / /
                                    \ V / / /
                                     \_/  \/

                                   V E C T O R
                                    Installer


--------------------------------------------------------------------------------

root@user:~# vector --version
vector: command not found

root@user:~# ls -la ~/.vector/bin/vector
-rwxr-xr-x 1 root root 160680968 Oct 19 17:29 /root/.vector/bin/vector
root@user:~# ~/.vector/bin/vector --version
vector 0.60.0 (x86_64-unknown-linux-gnu 0d0b358 2026-10-19 16:56:14.309955068)
root@user:~# echo 'export PATH="$HOME/.vector/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
root@user:~# vector --version
vector 0.60.0 (x86_64-unknown-linux-gnu 0d0b358 2026-10-19 16:56:14.309955068)

root@user:~# sudo mkdir -p /etc/vector
root@user:~# sudo vim /etc/vector/vector.yaml

root@user:~# vector validate /etc/vector/vector.yaml
√ Loaded ["/etc/vector/vector.yaml"]
√ Transforms configuration
√ Sinks configuration
x data_dir "/var/lib/vector/" does not exist

root@user:~# sudo mkdir -p /var/lib/vector
root@user:~# sudo mkdir -p /var/lib/vector

root@user:~# vector validate /etc/vector/vector.yaml
√ Loaded ["/etc/vector/vector.yaml"]
√ Transforms configuration
√ Sinks configuration
2026-10-27T21:53:17.514751Z  WARN sink{component_kind="sink" component_id=elasticsearch_out component_type=elasticsearch}: vector_core::tls::settings: The `verify_certificate` option is DISABLED, this may lead to security vulnerabilities.
√ Component configuration
√ Health check "elasticsearch_out"
------------------------------------


root@user:~# vector --config /etc/vector/vector.yaml
2026-10-27T21:54:00.911375Z  INFO vector::app: Log level is enabled. level="info"
2026-10-27T21:54:00.915134Z  INFO vector::app: Loading configs. paths=["/etc/vector/vector.yaml"]
2026-10-27T21:54:00.935036Z  WARN sink{component_kind="sink" component_id=elasticsearch_out component_type=elasticsearch}: vector_core::tls::settings: The `verify_certificate` option is DISABLED, this may lead to security vulnerabilities.
2026-10-27T21:54:01.138196Z  INFO vector::topology::running: Running healthchecks.
2026-10-27T21:54:01.139320Z  INFO vector: Vector has started. debug="false" version="0.60.0" arch="x86_64" revision="0d0b358 2026-10-19 16:56:14.309955068"
2026-10-27T21:54:01.139441Z  INFO vector::app: API is disabled, enable by setting `api.enabled` to `true` and use commands like `vector top`.
2026-10-27T21:54:01.140530Z  INFO source{component_kind="source" component_id=beats_in component_type=logstash}: vector::sources::util::net::tcp: Listening. addr=0.0.0.0:5044
2026-10-27T21:54:01.195561Z  INFO vector::topology::builder: Healthcheck passed.
```