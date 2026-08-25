# Движок отчетов

Движок отчетов использует ClickHouse как аналитическое хранилище для данных отчетов. В этом документе описаны Helm values, которые управляют включением движка отчетов и интеграцией с ClickHouse в чарте `pyrus-datacenter`.

## Комбинации values

### Движок отчетов выключен

По умолчанию движок отчетов выключен.

```yaml
reportEngine:
  enabled: false
```

### Встроенный ClickHouse

Используйте этот режим, если ClickHouse должен развертываться встроенным сабчартом `clickhouse`.

Чарт рендерит ресурсы [Altinity](https://altinity.com/kubernetes-operator/) `ClickHouseInstallation` и `ClickHouseKeeperInstallation`. Перед включением встроенного ClickHouse установите Altinity ClickHouse operator:

```sh
helm repo add pyrus-datacenter-k8s https://simplygoodsoftware.github.io/pyrus-datacenter-k8s
helm repo update

helm upgrade --install clickhouse-operator \
  pyrus-datacenter-k8s/clickhouse-operator \
  --namespace clickhouse-operator \
  --create-namespace \
  --wait
```

```yaml
reportEngine:
  enabled: true

clickhouse:
  internal: true

  keeper:
    enabled: true

  clickhouse:
    enabled: true
    users:
      pyrus_writer:
        password: <пароль пользователя>
```

### Внешний ClickHouse

Используйте этот режим, если ClickHouse управляется вне чарта `pyrus-datacenter`.

```yaml
reportEngine:
  enabled: true

clickhouse:
  internal: false

  # Заполните для replicated ClickHouse. Оставьте пустым для single-node mode.
  clusterName: <имя кластера>

  externalUser: <имя пользователя>
  externalUserPassword: <пароль пользователя>
  externalHost: <host clickhouse>
  externalPort: <port clickhouse>
```

Pyrus поддерживает только один шард ClickHouse. Используйте внешний кластер ClickHouse с одним шардом.

Пользователь ClickHouse должен обладать правами:

```yaml
grants:
  query:
    - >-
      GRANT SHOW,
      SELECT,
      INSERT,
      ALTER,
      CREATE TABLE,
      CREATE VIEW ON public.*,
      CREATE USER ON *.*,
      CLUSTER ON *.*,
      SELECT ON system.tables,
      CREATE ROW POLICY ON public.* WITH GRANT OPTION
    - GRANT CREATE DATABASE ON public.*
```

## Справочник values

Секции `clickhouse.keeper.settings`, `clickhouse.clickhouse.settings`, `clickhouse.clickhouse.users`, `clickhouse.clickhouse.profiles` и `clickhouse.clickhouse.quotas` шаблонизируются в формат Altinity operator. В них можно передавать вложенные YAML-настройки ClickHouse: чарт развернет их в ключи вида `section/subsection/key`, а operator примонтирует итоговую конфигурацию в pod. Список доступных настроек смотрите в [официальной документации ClickHouse](https://clickhouse.com/docs/operations/settings).

### Движок отчетов и режим ClickHouse

| Value | Default | Required | Описание |
| --- | --- | --- | --- |
| `reportEngine.enabled` | `false` | no | Включает или выключает движок отчетов. |
| `clickhouse.internal` | `true` | no | Если `true`, используется встроенный сабчарт `clickhouse`. Если `false`, используется внешний endpoint ClickHouse. |
| `clickhouse.clusterName` | `clickhouse` | no | Имя кластера ClickHouse. Если заполнено, движок отчетов использует replicated mode. Если пустое, используется single-node mode. |
| `clickhouse.externalHost` | `""` | внешний ClickHouse | HTTP host внешнего ClickHouse. Обязателен при `reportEngine.enabled=true` и `clickhouse.internal=false`. |
| `clickhouse.externalPort` | `""` | внешний ClickHouse | HTTP port внешнего ClickHouse. Обязателен при `reportEngine.enabled=true` и `clickhouse.internal=false`. |
| `clickhouse.externalUser` | `pyrus_writer` | внешний ClickHouse | Пользователь, под которым Pyrus подключается к внешнему ClickHouse. Обязателен при `reportEngine.enabled=true` и `clickhouse.internal=false`. |
| `clickhouse.externalUserPassword` | `pyruspwd` | внешний ClickHouse | Пароль для `clickhouse.externalUser`. Обязателен при `reportEngine.enabled=true` и `clickhouse.internal=false`. |
| `clickhouse.imagePullSecrets` | `[]` | no | Kubernetes Secrets для скачивания образов всеми pod'ами встроенного ClickHouse. Каждый элемент должен содержать `name`. |

### ClickHouse Keeper

| Value | Default | Required | Описание |
| --- | --- | --- | --- |
| `clickhouse.keeper.enabled` | `false` | встроенный ClickHouse | Включает ресурсы ClickHouse Keeper во встроенном сабчарте `clickhouse`. |
| `clickhouse.keeper.replicas` | `3` | встроенный ClickHouse | Количество реплик ClickHouse Keeper. |
| `clickhouse.keeper.nodeRoleSelectorLabel` | unset | no | Если задано, pod'ы Keeper будут запускаться на нодах с label `node-role.kubernetes.io/<value>: enabled`. |
| `clickhouse.keeper.image.repository` | `simplygoodsoftware/pyrus-clickhouse-keeper` | встроенный ClickHouse | Repository образа ClickHouse Keeper. |
| `clickhouse.keeper.image.tag` | `tagsContainers.All` | встроенный ClickHouse | Tag образа ClickHouse Keeper. Совпадает с версией Pyrus в `tagsContainers.All`. |
| `clickhouse.keeper.settings` | см. `values.yaml` | no | Вложенные настройки ClickHouse Keeper, которые чарт передает в Altinity operator. Здесь можно настраивать `prometheus`, `keeper_server`, `logger`, `coordination_settings` и другие параметры Keeper. |
| `clickhouse.keeper.resources.requests.cpu` | `100m` | встроенный ClickHouse | CPU request для pod'а Keeper. |
| `clickhouse.keeper.resources.requests.memory` | `512Mi` | встроенный ClickHouse | Memory request для pod'а Keeper. |
| `clickhouse.keeper.resources.limits.cpu` | `1000m` | встроенный ClickHouse | CPU limit для pod'а Keeper. |
| `clickhouse.keeper.resources.limits.memory` | `2Gi` | встроенный ClickHouse | Memory limit для pod'а Keeper. |
| `clickhouse.keeper.storage.size` | `10Gi` | встроенный ClickHouse | Размер persistent volume для каждой реплики ClickHouse Keeper. |

### ClickHouse server

| Value | Default | Required | Описание |
| --- | --- | --- | --- |
| `clickhouse.clickhouse.enabled` | `false` | встроенный ClickHouse | Включает ресурсы ClickHouse server во встроенном сабчарте `clickhouse`. |
| `clickhouse.clickhouse.shardsCount` | `1` | встроенный ClickHouse | Количество шардов ClickHouse. Pyrus поддерживает только `1`. |
| `clickhouse.clickhouse.replicasCount` | `2` | встроенный ClickHouse | Количество реплик ClickHouse. |
| `clickhouse.clickhouse.nodeRoleSelectorLabel` | unset | no | Если задано, pod'ы ClickHouse будут запускаться на нодах с label `node-role.kubernetes.io/<value>: enabled`. |
| `clickhouse.clickhouse.image.repository` | `simplygoodsoftware/pyrus-clickhouse` | встроенный ClickHouse | Repository образа ClickHouse server. |
| `clickhouse.clickhouse.image.tag` | `tagsContainers.All` | встроенный ClickHouse | Tag образа ClickHouse server. Совпадает с версией Pyrus в `tagsContainers.All`. |
| `clickhouse.clickhouse.settings` | см. `values.yaml` | no | Вложенные настройки ClickHouse server, которые чарт передает в Altinity operator. Здесь можно настраивать `prometheus`, `merge_tree`, лимиты памяти и подключений, caches, `logger`, `compression` и другие параметры ClickHouse. |
| `clickhouse.clickhouse.profiles` | `default`, `readonly`, `readwrite` | no | Профили ClickHouse users. Вложенные значения рендерятся как `profile/key`. |
| `clickhouse.clickhouse.quotas` | `default` | no | Quotas ClickHouse users. Вложенные значения рендерятся как `quota/interval/key`. |
| `clickhouse.clickhouse.users` | `default`, `pyrus_writer` | встроенный ClickHouse | Пользователи ClickHouse. Вложенные значения рендерятся как `user/key`. |
| `clickhouse.clickhouse.users.default.password` | `""` | no | Пароль пользователя `default`. |
| `clickhouse.clickhouse.users.default.networks.ip` | `127.0.0.1/32` | no | Сеть, из которой разрешено подключение под пользователем `default`. |
| `clickhouse.clickhouse.users.default.profile` | `default` | no | Профиль пользователя `default`. |
| `clickhouse.clickhouse.users.default.quota` | `default` | no | Quota пользователя `default`. |
| `clickhouse.clickhouse.users.pyrus_writer.password` | `pyruspwd` | встроенный ClickHouse | Пароль writer пользователя для подключения Pyrus к встроенному ClickHouse. Переопределяйте это значение в production. |
| `clickhouse.clickhouse.users.pyrus_writer.networks.ip` | `10.0.0.0/8` | встроенный ClickHouse | Сеть, из которой разрешено подключение под пользователем `pyrus_writer`. |
| `clickhouse.clickhouse.users.pyrus_writer.grants.query` | см. пример выше | встроенный ClickHouse | SQL grants пользователя `pyrus_writer`. |
| `clickhouse.clickhouse.resources.requests.cpu` | `1` | встроенный ClickHouse | CPU request для pod'а ClickHouse server. |
| `clickhouse.clickhouse.resources.requests.memory` | `2Gi` | встроенный ClickHouse | Memory request для pod'а ClickHouse server. |
| `clickhouse.clickhouse.resources.limits.cpu` | `4` | встроенный ClickHouse | CPU limit для pod'а ClickHouse server. |
| `clickhouse.clickhouse.resources.limits.memory` | `8Gi` | встроенный ClickHouse | Memory limit для pod'а ClickHouse server. |
| `clickhouse.clickhouse.storage.size` | `100Gi` | встроенный ClickHouse | Размер persistent volume для каждой реплики ClickHouse. |

### Monitoring

| Value | Default | Required | Описание |
| --- | --- | --- | --- |
| `clickhouse.monitoring.enabled` | `false` | no | Включает PodMonitor ресурсы для Keeper и ClickHouse server во встроенном сабчарте `clickhouse`. |
| `clickhouse.monitoring.interval` | `30s` | monitoring | Интервал сбора метрик для monitoring встроенного ClickHouse. |

### Backup and restore

Бэкапится только ClickHouse. Keeper не бэкапится, потому что хранит состояние, которое будет восстановлено из ClickHouse при восстановлении кластера. Архивирование журналов не используется.

| Value | Default | Required | Описание |
| --- | --- | --- | --- |
| `clickhouse.backup.enabled` | `false` | no | Включает backup sidecar в pod ClickHouse и CronJob для регулярных backup. |
| `clickhouse.backup.restore` | `false` | no | Включает restore job для восстановления последнего backup при установке или обновлении чарта, а также добавляет backup sidecar. |
| `clickhouse.backup.image.repository` | `simplygoodsoftware/pyrus-clickhouse-backup` | backup | Repository образа `clickhouse-backup`. |
| `clickhouse.backup.image.tag` | `tagsContainers.All` | backup | Tag образа `clickhouse-backup`. Совпадает с версией Pyrus в `tagsContainers.All`. |
| `clickhouse.backup.debug` | `false` | backup | Включает debug-режим `clickhouse-backup` и S3 debug output. |
| `clickhouse.backup.schedule` | `0 0 * * *` | backup | Расписание backup CronJob в cron-формате. |
| `clickhouse.backup.FULL_BACKUP_WEEKDAY` | `6` | backup | День недели для полного backup: `1` - Monday, `7` - Sunday. В остальные дни создается incremental backup. |
| `clickhouse.backup.BACKUP_PASSWORD` | unset | backup | Пароль пользователя `backup`, под которым выполняется backup и restore. |
| `clickhouse.backup.BACKUPS_TO_KEEP_REMOTE` | `7` | backup | Количество remote backup, которые хранит `clickhouse-backup`. |
| `clickhouse.backup.network` | `10.0.0.0/16` | backup | Подсеть, из которой разрешено подключение пользователю `backup`. |
| `clickhouse.backup.S3_ENDPOINT` | unset | backup | S3 endpoint для remote backup storage. |
| `clickhouse.backup.S3_REGION` | unset | backup | S3 region. Необязателен для некоторых S3-compatible storage. |
| `clickhouse.backup.S3_BUCKET` | unset | backup | S3 bucket для backup. |
| `clickhouse.backup.S3_ACCESS_KEY` | unset | backup | Access key для S3. |
| `clickhouse.backup.S3_SECRET_KEY` | unset | backup | Secret key для S3. |
| `clickhouse.backup.S3_PATH` | `clickhouse/shard-{shard}` | backup | Путь backup в bucket. Макрос `{shard}` заменяется номером шарда. |
