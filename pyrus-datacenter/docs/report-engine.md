# Report Engine

Report Engine uses ClickHouse as analytical storage for report data. This document describes the Helm values that control Report Engine and ClickHouse integration in the `pyrus-datacenter` chart.

## Value Combinations

### Report Engine Disabled

Report Engine is disabled by default.

```yaml
reportEngine:
  enabled: false
```

### Bundled ClickHouse

Use this mode when ClickHouse should be deployed by the bundled `clickhouse` subchart.

The chart renders [Altinity](https://altinity.com/kubernetes-operator/) `ClickHouseInstallation` and `ClickHouseKeeperInstallation` resources. Install the Altinity ClickHouse operator before enabling bundled ClickHouse:

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
        password: <user password>
```

### External ClickHouse

Use this mode when ClickHouse is managed outside of the `pyrus-datacenter` chart.

```yaml
reportEngine:
  enabled: true

clickhouse:
  internal: false

  # Set for replicated ClickHouse. Leave empty for single-node mode.
  clusterName: <cluster name>

  externalUser: <username>
  externalUserPassword: <user password>
  externalHost: <clickhouse host>
  externalPort: <clickhouse port>
```

Pyrus supports only one ClickHouse shard. Use a single-shard external ClickHouse cluster.

The ClickHouse user must have these grants:

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

## Values Reference

The `clickhouse.keeper.settings`, `clickhouse.clickhouse.settings`, `clickhouse.clickhouse.users`, `clickhouse.clickhouse.profiles`, and `clickhouse.clickhouse.quotas` sections are rendered into the Altinity operator format. You can pass nested ClickHouse YAML settings there: the chart expands them into keys like `section/subsection/key`, and the operator mounts the resulting configuration into the pod. See the list of available settings in the [official ClickHouse documentation](https://clickhouse.com/docs/operations/settings).

### Report Engine and ClickHouse Mode

| Value | Default | Required | Description |
| --- | --- | --- | --- |
| `reportEngine.enabled` | `false` | no | Enables or disables Report Engine. |
| `clickhouse.internal` | `true` | no | If `true`, uses the bundled `clickhouse` subchart. If `false`, uses an external ClickHouse endpoint. |
| `clickhouse.clusterName` | `clickhouse` | no | ClickHouse cluster name. If set, Report Engine uses replicated mode. If empty, it uses single-node mode. |
| `clickhouse.externalHost` | `""` | external ClickHouse | External ClickHouse HTTP host. Required when `reportEngine.enabled=true` and `clickhouse.internal=false`. |
| `clickhouse.externalPort` | `""` | external ClickHouse | External ClickHouse HTTP port. Required when `reportEngine.enabled=true` and `clickhouse.internal=false`. |
| `clickhouse.externalUser` | `pyrus_writer` | external ClickHouse | User used by Pyrus to connect to external ClickHouse. Required when `reportEngine.enabled=true` and `clickhouse.internal=false`. |
| `clickhouse.externalUserPassword` | `pyruspwd` | external ClickHouse | Password for `clickhouse.externalUser`. Required when `reportEngine.enabled=true` and `clickhouse.internal=false`. |
| `clickhouse.imagePullSecrets` | `[]` | no | Kubernetes image pull secrets used by all bundled ClickHouse pods. Each item must contain a `name`. |

### ClickHouse Keeper

| Value | Default | Required | Description |
| --- | --- | --- | --- |
| `clickhouse.keeper.enabled` | `false` | bundled ClickHouse | Enables ClickHouse Keeper resources in the bundled `clickhouse` subchart. |
| `clickhouse.keeper.replicas` | `3` | bundled ClickHouse | Number of ClickHouse Keeper replicas. |
| `clickhouse.keeper.nodeRoleSelectorLabel` | unset | no | If set, Keeper pods are scheduled on nodes with the `node-role.kubernetes.io/<value>: enabled` label. |
| `clickhouse.keeper.image.repository` | `clickhouse/clickhouse-keeper` | bundled ClickHouse | ClickHouse Keeper image repository. |
| `clickhouse.keeper.image.tag` | `26.1.2.11-alpine` | bundled ClickHouse | ClickHouse Keeper image tag. |
| `clickhouse.keeper.settings` | see `values.yaml` | no | Nested ClickHouse Keeper settings passed by the chart to the Altinity operator. Use this section to configure `prometheus`, `keeper_server`, `logger`, `coordination_settings`, and other Keeper parameters. |
| `clickhouse.keeper.resources.requests.cpu` | `100m` | bundled ClickHouse | CPU request for the Keeper pod. |
| `clickhouse.keeper.resources.requests.memory` | `512Mi` | bundled ClickHouse | Memory request for the Keeper pod. |
| `clickhouse.keeper.resources.limits.cpu` | `1000m` | bundled ClickHouse | CPU limit for the Keeper pod. |
| `clickhouse.keeper.resources.limits.memory` | `2Gi` | bundled ClickHouse | Memory limit for the Keeper pod. |
| `clickhouse.keeper.storage.size` | `10Gi` | bundled ClickHouse | Persistent volume size for each ClickHouse Keeper replica. |

### ClickHouse Server

| Value | Default | Required | Description |
| --- | --- | --- | --- |
| `clickhouse.clickhouse.enabled` | `false` | bundled ClickHouse | Enables ClickHouse server resources in the bundled `clickhouse` subchart. |
| `clickhouse.clickhouse.shardsCount` | `1` | bundled ClickHouse | Number of ClickHouse shards. Pyrus supports only `1`. |
| `clickhouse.clickhouse.replicasCount` | `2` | bundled ClickHouse | Number of ClickHouse replicas. |
| `clickhouse.clickhouse.nodeRoleSelectorLabel` | unset | no | If set, ClickHouse pods are scheduled on nodes with the `node-role.kubernetes.io/<value>: enabled` label. |
| `clickhouse.clickhouse.image.repository` | `clickhouse/clickhouse-server` | bundled ClickHouse | ClickHouse server image repository. |
| `clickhouse.clickhouse.image.tag` | `26.1.2.11-alpine` | bundled ClickHouse | ClickHouse server image tag. |
| `clickhouse.clickhouse.settings` | see `values.yaml` | no | Nested ClickHouse server settings passed by the chart to the Altinity operator. Use this section to configure `prometheus`, `merge_tree`, memory and connection limits, caches, `logger`, `compression`, and other ClickHouse parameters. |
| `clickhouse.clickhouse.profiles` | `default`, `readonly`, `readwrite` | no | ClickHouse user profiles. Nested values are rendered as `profile/key`. |
| `clickhouse.clickhouse.quotas` | `default` | no | ClickHouse user quotas. Nested values are rendered as `quota/interval/key`. |
| `clickhouse.clickhouse.users` | `default`, `pyrus_writer` | bundled ClickHouse | ClickHouse users. Nested values are rendered as `user/key`. |
| `clickhouse.clickhouse.users.default.password` | `""` | no | Password for the `default` user. |
| `clickhouse.clickhouse.users.default.networks.ip` | `127.0.0.1/32` | no | Network allowed to connect as the `default` user. |
| `clickhouse.clickhouse.users.default.profile` | `default` | no | Profile for the `default` user. |
| `clickhouse.clickhouse.users.default.quota` | `default` | no | Quota for the `default` user. |
| `clickhouse.clickhouse.users.pyrus_writer.password` | `pyruspwd` | bundled ClickHouse | Writer user password used by Pyrus to connect to bundled ClickHouse. Override this value in production. |
| `clickhouse.clickhouse.users.pyrus_writer.networks.ip` | `10.0.0.0/8` | bundled ClickHouse | Network allowed to connect as the `pyrus_writer` user. |
| `clickhouse.clickhouse.users.pyrus_writer.grants.query` | see example above | bundled ClickHouse | SQL grants for the `pyrus_writer` user. |
| `clickhouse.clickhouse.resources.requests.cpu` | `1` | bundled ClickHouse | CPU request for the ClickHouse server pod. |
| `clickhouse.clickhouse.resources.requests.memory` | `2Gi` | bundled ClickHouse | Memory request for the ClickHouse server pod. |
| `clickhouse.clickhouse.resources.limits.cpu` | `4` | bundled ClickHouse | CPU limit for the ClickHouse server pod. |
| `clickhouse.clickhouse.resources.limits.memory` | `8Gi` | bundled ClickHouse | Memory limit for the ClickHouse server pod. |
| `clickhouse.clickhouse.storage.size` | `100Gi` | bundled ClickHouse | Persistent volume size for each ClickHouse replica. |

### Monitoring

| Value | Default | Required | Description |
| --- | --- | --- | --- |
| `clickhouse.monitoring.enabled` | `false` | no | Enables PodMonitor resources for Keeper and ClickHouse server in the bundled `clickhouse` subchart. |
| `clickhouse.monitoring.interval` | `30s` | monitoring | Metrics scrape interval for bundled ClickHouse monitoring. |

### Backup and Restore

Only ClickHouse is backed up. Keeper is not backed up because it stores state that will be restored from ClickHouse when the cluster is restored. Log archiving is not used.

| Value | Default | Required | Description |
| --- | --- | --- | --- |
| `clickhouse.backup.enabled` | `false` | no | Enables the backup sidecar in the ClickHouse pod and the CronJob for regular backups. |
| `clickhouse.backup.restore` | `false` | no | Enables the restore job that restores the latest backup during chart install or upgrade, and also adds the backup sidecar. |
| `clickhouse.backup.image.repository` | `altinity/clickhouse-backup` | backup | `clickhouse-backup` image repository. |
| `clickhouse.backup.image.tag` | `2.6.42` | backup | `clickhouse-backup` image tag. |
| `clickhouse.backup.debug` | `false` | backup | Enables `clickhouse-backup` debug mode and S3 debug output. |
| `clickhouse.backup.schedule` | `0 0 * * *` | backup | Backup CronJob schedule in cron format. |
| `clickhouse.backup.FULL_BACKUP_WEEKDAY` | `6` | backup | Weekday for full backups: `1` - Monday, `7` - Sunday. Incremental backups are created on other days. |
| `clickhouse.backup.BACKUP_PASSWORD` | unset | backup | Password for the `backup` user used for backup and restore. |
| `clickhouse.backup.BACKUPS_TO_KEEP_REMOTE` | `7` | backup | Number of remote backups kept by `clickhouse-backup`. |
| `clickhouse.backup.network` | `10.0.0.0/16` | backup | Subnet allowed to connect as the `backup` user. |
| `clickhouse.backup.S3_ENDPOINT` | unset | backup | S3 endpoint for remote backup storage. |
| `clickhouse.backup.S3_REGION` | unset | backup | S3 region. Optional for some S3-compatible storage. |
| `clickhouse.backup.S3_BUCKET` | unset | backup | S3 bucket for backups. |
| `clickhouse.backup.S3_ACCESS_KEY` | unset | backup | S3 access key. |
| `clickhouse.backup.S3_SECRET_KEY` | unset | backup | S3 secret key. |
| `clickhouse.backup.S3_PATH` | `clickhouse/shard-{shard}` | backup | Backup path in the bucket. The `{shard}` macro is replaced with the shard number. |
