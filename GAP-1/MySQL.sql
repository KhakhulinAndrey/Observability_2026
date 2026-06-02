# Создаем пользователя для экспортера
sudo useradd --no-create-home --shell /bin/false mysqld_exporter

# Создаем пользователя в MySQL для сбора метрик
sudo mysql -e "CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'хххххххх';"
sudo mysql -e "GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"