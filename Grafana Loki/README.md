## Домашнее задание 11. Grafana Loki
### Вам предстоит заменить Elasticsearch на Grafana Loki. Убедитесь, что данные поступают в Grafana Loki и к ним есть доступ.

#### Часть 1: Установка Grafana Loki (Вторая ВМ)
```
root@user:~# cd /tmp
root@user:/tmp# curl -O -L "https://github.com/grafana/loki/releases/latest/download/loki-linux-amd64.zip"
root@user:/tmp# unzip loki-linux-amd64.zip
root@user:/tmp# sudo mv loki-linux-amd64 /usr/local/bin/loki
root@user:/tmp# sudo chmod +x /usr/local/bin/loki
root@user:/tmp#
root@user:/tmp# loki --version
loki, version 3.7.9 (branch: release-3.7.x, revision: d3b4a2f7)
  build user:       root@c03d5eaf3258
  build date:       2026-10-20T21:43:16Z
  go version:       go1.26.10
  platform:         linux/amd64
  tags:             netgo

root@user:/tmp# sudo useradd --system --no-create-home --shell /bin/false loki
root@user:/tmp# sudo mkdir -p /etc/loki /var/lib/loki
root@user:/tmp# sudo chown -R loki:loki /etc/loki /var/lib/loki

root@user:/tmp# sudo vim /etc/loki/loki-config.yaml

root@user:/tmp# sudo vim /etc/systemd/system/loki.service

root@user:/tmp# sudo systemctl daemon-reload
root@user:/tmp# sudo systemctl start loki
root@user:/tmp# sudo systemctl enable loki
Created symlink /etc/systemd/system/multi-user.target.wants/loki.service → /etc/systemd/system/loki.service.
root@user:/tmp# sudo systemctl status loki --no-pager
```

#### Часть 2: Установка Grafana Alloy (Первая ВМ)
```
andrew@VLADIMIR-PC:/tmp$ sudo useradd --no-create-home --shell /bin/false alloy
andrew@VLADIMIR-PC:/tmp$ sudo mkdir -p /etc/alloy /var/lib/alloy
andrew@VLADIMIR-PC:/tmp$ sudo chown root:alloy /etc/alloy
andrew@VLADIMIR-PC:/tmp$ sudo chmod 750 /etc/alloy
andrew@VLADIMIR-PC:/tmp$ sudo chown -R alloy:alloy /var/lib/alloy
andrew@VLADIMIR-PC:/tmp$ sudo chmod 750 /var/lib/alloy
andrew@VLADIMIR-PC:/tmp$ cd /tmp
andrew@VLADIMIR-PC:/tmp$ curl -O -L "https://github.com/grafana/alloy/releases/latest/download/alloy-linux-amd64.zip"
andrew@VLADIMIR-PC:/tmp$ unzip alloy-linux-amd64.zip
andrew@VLADIMIR-PC:/tmp$ sudo mv alloy-linux-amd64 /usr/local/bin/alloy
andrew@VLADIMIR-PC:/tmp$ sudo chmod +x /usr/local/bin/alloy
andrew@VLADIMIR-PC:/tmp$ alloy --version
alloy, version v1.21.3 (branch: HEAD, revision: f2108cd)
  build user:       root@eb0633faf47d
  build date:       2026-10-28T16:58:58Z
  go version:       go1.27.3
  platform:         linux/amd64
  tags:             gore2regex,netgo,embedalloyui,promtail_journal_enabled

andrew@VLADIMIR-PC:/tmp$ sudo usermod -aG adm alloy
andrew@VLADIMIR-PC:/tmp$ sudo usermod -aG mysql alloy
andrew@VLADIMIR-PC:/tmp$ id alloy
uid=1008(alloy) gid=1008(alloy) groups=1008(alloy),4(adm),108(mysql)
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/alloy/config.alloy
andrew@VLADIMIR-PC:/tmp$ sudo vim /etc/systemd/system/alloy.service


andrew@VLADIMIR-PC:/tmp$ sudo systemctl daemon-reload
andrew@VLADIMIR-PC:/tmp$ sudo systemctl start alloy
andrew@VLADIMIR-PC:/tmp$ sudo systemctl enable alloy
Created symlink '/etc/systemd/system/multi-user.target.wants/alloy.service' → '/etc/systemd/system/alloy.service'.
andrew@VLADIMIR-PC:/tmp$ sudo systemctl status alloy
```