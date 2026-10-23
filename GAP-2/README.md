## Задание 4
### На VM с установленным Prometheus установите Grafana последней версии доступной на момент выполнения ДЗ:

+ Создайте внутри Grafana папки с названиями infra и app;
+ Внутри директории infra создайте дашборд, который будет отображать сводную информацию по инфраструктуре (CPU, RAM, Network, etc.);
+ Внутри директории app создайте дашборд, который будет отображать сводную информацию о CMS (доступность компонентов, время ответа, etc.);

### Задание со звездочкой
1. при помощи Grafana создайте alert о недоступности одного из компонентов CMS и инфраструктуры;
2. создайте DrillDown dashboard, который будет отображать сводную информацию по инфраструктуре, но нажав на конкретный инстанс можно получить полную информацию.


```
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo apt-get install -y adduser libfontconfig1 musl
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ wget https://dl.grafana.com/grafana/release/13.2.3/grafana_13.2.3_36482603486_linux_amd64.deb
grafana_13.2.3_36482603486_li 100%[=================================================>] 362,65M   930KB/s    за 7m 59s

2026-10-23 22:28:34 (775 KB/s) - ‘grafana_13.2.3_36482603486_linux_amd64.deb’ сохранён [380266356/380266356]

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo dpkg -i grafana_13.2.3_36482603486_linux_amd64.deb

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl daemon-reload
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl start grafana-server
andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl enable grafana-server

andrew@VLADIMIR-PC:/mnt/c/Users/97976$ sudo systemctl status grafana-server
● grafana-server.service - Grafana instance
     Loaded: loaded (/usr/lib/systemd/system/grafana-server.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-10-23 22:32:15 +04; 12s ago
 Invocation: fb02064b5c9648648bfd0eb926cc4956
       Docs: http://docs.grafana.org
   Main PID: 1301 (grafana)
      Tasks: 14 (limit: 9155)
     Memory: 232.4M (peak: 233M)
        CPU: 1.803s
     CGroup: /system.slice/grafana-server.service
             └─1301 /usr/share/grafana/bin/grafana server --config=/etc/grafana/grafana.ini --pidfile=/run/grafana/graf>
```