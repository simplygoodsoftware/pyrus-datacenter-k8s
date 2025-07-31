[![PyrusLogo](https://pyrus.com/images/logo/logo_small_x2.png)](https://pyrus.com)

## Pyrus Datacenter K8S
Pyrus Datacenter K8S — безоблачная версия Pyrus, которая поставляется в виде Helm Chart и развёртывается в системе Kubernetes.\
Платформа поддерживает работу в режиме High Availability.\
Более подробную информацию о Pyrus Datacenter можно узнать в нашей [справке](https://pyrus.com/ru/help/datacenter).

## Требования
Для запуска Pyrus Datacenter вам понадобятся:
* Лицензия Pyrus Datacenter
* SSL сертификат на выбранное вами доменное имя
* Логин и пароль учётной записи вашего SMTP сервера, для отправки почтовых сообщений пользователям
* S3 с параметрами доступа на следующие типы провайдеров: Aws, MinIo, Azure, Mts, VkCloud
  
## Конфигурация

В данном разделе описаны необходимые для запуска Pyrus Datacenter параметры установки.

### Выбор yandex репозитория образов Pyrus Datacenter
```
containersRepo:
  default: cr.yandex/crpn0l4dp22f8mv5ln18

elasticsearch:
  image: "cr.yandex/crpn0l4dp22f8mv5ln18/elastic-selfhosted"
```
### Форсирование версии Pyrus Datacenter
```
tagsContainers:
  All: 1.9.0
```

### Лицензия
```
pyrusSetupParam:
  license: <LICENSE>
```

### Эл. почта и пароль администратора Pyrus Datacenter
```
pyrusSetupParam:
  adminEmail: <ADMINEMAIL>
  adminPass: <ADMINPASSWORD>
```

### Доменное имя
```
values-ingress-dir:
  tls:
    - hosts:
        - <DOMAIN>
```

### SSL сертификат
Добавьте Kubernetes Secret с данными вашего сертификата
```
kubectl create secret generic pyrus-ssl --from-file=tls.crt=your_cert.crt --from-file=tls.key=your_key.key
```

### Параметры Ingress-NGINX
```
  allow-backend-server-header: "true"
  allow-snippet-annotations: "true"
  proxy_next_upstream: error timeout invalid_header http_502 http_503 http_504
  proxy-stream-timeout: 2m
  proxy-stream-next-upstream-timeout: 5s
  proxy-stream-next-upstream-tries: 7
  upstream-keepalive-time: 20m
  client-header-buffer-size: "8k"
  large-client-header-buffers: "8 16k"
```

## Резервное копирование и восстановление данных

Pyrus Datacenter поставляется с внутренней СУБД PostgreSQL, используемой для хранения данных.\
С целью обеспечения сохранности данных реализовано автоматическое резервное копирование на основе [wal-g](https://github.com/wal-g/wal-g), позволяющее выгружать копии в AWS S3 или другое S3-совместимое хранилище.\
Для работы данного функционала необходимо указать параметры S3:

```
standalonePostgreSQLBackup:
  AWS_ACCESS_KEY_ID: <ACCESSKEY>  
  AWS_SECRET_ACCESS_KEY: <SECRETKEY>  
  WALG_S3_PREFIX: s3://<S3BUCKET>/<DIRECTORY>
```

При использовании S3-совместимого хранилища, отличного от AWS S3:
```
standalonePostgreSQLBackup:
  AWS_ENDPOINT: <S3_URL>
```

### Описание процесса резервного копирования

Резервное копирование запускается автоматически.\
Полная резервная копия по умолчанию делается в 01:00 ежедневно.\
Для изменения периодичности снятия резервной копии, вы можете воспользоваться следующей SQL командой в контейнере PostgreSQL: 

```
--                    ┌───────────── min (0 - 59)
--                    │ ┌────────────── hour (0 - 23)
--                    │ │ ┌─────────────── day of month (1 - 31)
--                    │ │ │ ┌──────────────── month (1 - 12)
--                    │ │ │ │ ┌───────────────── day of week (0 - 6) (0 to 6 are Sunday to
--                    │ │ │ │ │                  Saturday, or use names; 7 is also Sunday)
--                    * * * * *
SELECT cron.schedule('0 1 * * *', $$SELECT backup_manage(RETAIN_FIND_FULL integer, WALG_DELTA_MAX_STEPS integer)$$);
```

Параметр *RETAIN_FIND_FULL* указывает количество резервных копий, сохраняемых в S3.\
По умолчанию - 7 резервных копий.
 
Параметр *WALG_DELTA_MAX_STEPS* управляет количеством шагов, на которые дельта-копия максимально отстаёт 
от полной копии.\
По умолчанию - 3 шага.

Все задания можно посмотреть sql командой:
```
select * from cron.job;
```

### Восстановление из резервной копии

Для восстановления резервной копии необходимо указать в **ENVIRONMENT** контейнера *pyrus-postgres* имя точки восстановления.\
Например, для последней точки:
```
RESTORE_NAME: LATEST
```

Список резервных копий можно посмотреть командой:
```
wal-g backup-list
```

Восстановление из копии начнётся только если директория ${PGDATA} будет пустой.\
В обратном случае, процесс восстановления будет проигнорирован и система запустится из файлов расположенных в данной директории, либо инициализировать чистую базу при их отсутствии.

## Установка в конфигурации с внешними БД

Существует возможность использовать внешние базы данных, не устанавливая их в рамках данного чарта. Ниже приведены рекомендуемые примеры конфигураций и образов.

### Требования к PostgreSQL
Необходимо наличие следующих модулей:
- `pg_cron`
- `wal2json`

Рекомендуемые образы:
- **Для standalone-версии**: `cr.yandex/crpn0l4dp22f8mv5ln18/pyrus-pgsql-16:YOURVERSION`
- **Для кластерной системы на базе Patroni**: `cr.yandex/crpj6igvm2ge2h2jahpu/spilo-17:0.17`

Для standalone-версии PostgreSql с нашим образом дополнительные конфигурации не требуются.

При использовании кластерной версии на базе postgres-operator рекомендуется следующая конфигурация:
```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: pyrusadm.postgres.credentials.postgresql.acid.zalan.do
  labels:
    application: spilo
    cluster-name: postgres
    team: pyrus
data:
  username: cHlydXNhZG0=
  password: cHlydXNwd2Q=
---
apiVersion: "acid.zalan.do/v1"
kind: postgresql
metadata:
  name: postgres
spec:
  teamId: pyrus
  dockerImage: cr.yandex/crpj6igvm2ge2h2jahpu/spilo-17:0.17
  enableConnectionPooler: true
  volume:
    size: 100Gi
  numberOfInstances: 2
  users:
    pyrusadm:
    - superuser
    - createdb
  databases:
    pyrus-logs: pyrusadm
    pyrusdb: pyrusadm
  preparedDatabases:
  postgresql:
    version: "17"
    parameters:
      password_encryption: scram-sha-256
      shared_preload_libraries: pg_cron,bg_mon,pg_stat_statements,pg_stat_kcache,pgextwlist,pg_auth_mon,set_user,auto_explain
      cron.database_name: postgres
      cron.use_background_workers: "on"
      archive_timeout : 900s

      cron.log_run: "false"
      cron.log_statement: "false"
      wal_level: logical
  patroni:
    synchronous_mode: true

    pg_hba:
    - local   all          all                          trust
    - hostssl all          +zalandos 127.0.0.1/32       pam
    - host    all          all       127.0.0.1/32       trust
    - hostssl all          +zalandos ::1/128            pam
    - host    all          all       ::1/128            trust
    - local   replication  standby                      trust
    - hostssl replication  standby   all                md5
    - hostssl all          +zalandos all                pam
    - host    all          all       all                md5
    slots:
      pyrus_wal:
        database: pyrusdb
        plugin: wal2json
        type: logical
  connectionPooler:
    dockerImage: cr.yandex/crpj6igvm2ge2h2jahpu/pgbouncer:0.9
    numberOfInstances: 2
    maxDBConnections: 200
    mode: session
    schema: "pooler"
    user: pooler

```

### Требования к Elasticsearch

**Необходимые модули:**
- hunspell
- analysis-jmorphy2

**Рекомендуемый образ:**
`cr.yandex/crpn0l4dp22f8mv5ln18/elastic-selfhosted:YOURVERSION`

**Для кластерной конфигурации в Kubernetes:**
Рекомендуется использовать чарт из текущей сборки:
`pyrus-datacenter/charts/elasticsearch`

**Рекомендуемые параметры:**
```yaml
esJavaOpts: "-Xms1g -Xmx1g"
image: "simplygoodsoftware/elastic-selfhosted"
imageTag: "7.17.10"
clusterHealthCheckParams: "wait_for_status=green&timeout=30s"
resources:
  requests:
    cpu: "500m"
    memory: "1Gi"
  limits:
    cpu: "60"
    memory: "200Gi"
extraEnvs:
  - name: cluster.name
    value: docker-cluster
  - name: indices.recovery.max_bytes_per_sec
    value: "600mb"
  - name: indices.fielddata.cache.size
    value: "40%"
  - name: indices.breaker.fielddata.limit
    value: "40%"
  - name: indices.breaker.request.limit
    value: "60%"
  - name: script.max_compilations_rate
    value: "100/1m"
extraVolumes:
  - name: elastichsearch-cm-to-default
    configMap:
      name: elastichsearch-cm-to-default
extraVolumeMounts:
  - name: elastichsearch-cm-to-default
    mountPath: /usr/share/elasticsearch/config/elasticsearch.yml
    subPath: elasticsearch.yml
```

Конфигурация для файла elasticsearch.yml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: elastichsearch-cm-to-default
data:
  elasticsearch.yml: |
    cluster.name: "docker-cluster"
    network.host: 0.0.0.0
```

### Pyrus - минимально необходимая конфигурация
Пожалуйста, внесите необходимые изменения в следующие параметры:
- Укажите актуальные IP-адреса или доменные имена
- Проверьте корректность портов подключения
- Обновите логины и пароли
- Убедитесь в корректности путей подключения

```yaml
forceIngressClass: nginx

database:
  external: true

preview:
  external: true

logs:
  external: true

elasticsearch:
  internalChart: false

connectionStringsCreds:
  MAIN_CONN_STRING: >
    {
      "ConnectionName": "default",
      "ConnectionString": "Server=pyrus-postgresql-pooler.pyrus-postgresql.svc.cluster.local;Port=5432;Username=pyrusadm;Password=pyruspwd;Database=pyrusdb;",
      "DatabaseEngine": "Postgres",
      "DatabaseType": "Data"
    }
  PRIVATE_LOGS_CONN_STRING: >
    {
      "ConnectionName": "privateLogs",
      "ConnectionString": "Server=pyrus-postgresql-logs-pooler.pyrus-postgresql-logs.svc.cluster.local;Port=5432;Username=pyrusadm;Password=pyruspwd;Database=pyrus_logs;",
      "DatabaseEngine": "Postgres",
      "DatabaseType": "PrivateLogs"
    }
  PUBLIC_LOGS_CONN_STRING: >
    {
      "ConnectionName": "publicLogs",
      "ConnectionString": "Server=pyrus-postgresql-logs-pooler.pyrus-postgresql-logs.svc.cluster.local;Port=5432;Username=pyrusadm;Password=pyruspwd;Database=pyrus_logs;",
      "DatabaseEngine": "Postgres",
      "DatabaseType": "PublicLogs"
    }
  FILEDATA_CONN_STRING: >
    {
     "ConnectionName": "files",
     "ConnectionString": "Server=pyrus-postgresql-pooler.pyrus-postgresql.svc.cluster.local;Port=5432;Username=pyrusadm;Password=pyruspwd;Database=pyrusdb;",
     "DatabaseEngine": "Postgres",
     "DatabaseType": "Files"
    }
  NATS_HA_REPLICAS: "3"

webSecrets:
  pyrus-ssl:
    tls.crt: ...
    tls.key: ...
    tls.pem: ...

values-ingress-dir:
  secretNameDefault: pyrus-ssl
  tls:
    - hosts:
      - pyrus.yourcompany.com

pyrusSetupParam:
  adminEmail: ...
  adminPass: ...
  license: ...
  s3:
    keyId: ...
    secretKey: ...
    buket: ...
    storageType: ...
    S3_BLOB_STORAGE_ENDPOINT: ...
  setupById:
    105119: http://elasticsearch-master.pyrus-elastic.svc.cluster.local:9200
    #105121: ELASTIC_PASSWORD
    #105120: ELASTIC_USER

waitEndpoints:
  WaitOnEnd:
    - sh
    - -c
    - >
      kubectl wait --for=condition=complete job.batch/set-pyrus-setupparam --timeout=600s
      &&
      kubectl wait --for=condition=complete job -l app=upgrade-version-{{ .Values.tagsContainers.All }} --timeout=600s
  pyrus-preview-generator:
    - pyrus-nats
  pyrus-web-api:
    - pyrus-nats
  pyrus-file-service:
    - pyrus-nats
    - pyrus-identity-server
  pyrus-bind-service:
    - pyrus-nats
  pyrus-mail-reader:
    - pyrus-nats
  pyrus-mail-sender:
    - pyrus-nats
  pyrus-async-worker:
    - pyrus-nats
  pyrus-notification-service:
    - pyrus-nats
  pyrus-identity-server:
    - pyrus-nats
  pyrus-hocus:
    - pyrus-nats

```

Выполните установку следующей командой:
```sh
helm secrets -n pyrus install --create-namespace pyrus-dc pyrus-datacenter -f yourcompany.values.yaml
```

