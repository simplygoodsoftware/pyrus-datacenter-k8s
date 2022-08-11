[![PyrusLogo](https://pyrus.com/images/logo/logo_small_x2.png)](https://pyrus.com)

## Pyrus Datacenter K8S
Pyrus Datacenter K8S is an on-premise version of Pyrus, distributed as a Helm Chart to be installed in Kubernetes.\
The system works as a High Availability cluster.\

## Requirements
To successfully install Pyrus Datacenter you'll need:
* Pyrus Datacenter license
* SSL certificate for a domain of your choice
* Login and password for an SMTP server that's going to be needed to send mail to users
  
## Configuration

### Pyrus Datacenter version
```
tagsContainers:
  All: 1.3.3
```

### License
```
pyrusSetupParam:
  license: <LICENSE>
```

### E-mail and password for the administrator of Pyrus Datacenter
```
pyrusSetupParam:
  adminEmail: <ADMINEMAIL>
  adminPass: <ADMINPASSWORD>
```

### URL
```
values-ingress-dir:
  tls:
    - hosts:
        - <DOMAIN>
```

### SSL certificate
Add a Kubernetes Secret with your certificate and keys
```
kubectl create secret generic pyrus-ssl --from-file=tls.crt=your_cert.crt --from-file=tls.key=your_key.key
```

### Ingress-NGINX parameters
```
  allow-backend-server-header: "true"
  allow-snippet-annotations: "true"
  proxy_next_upstream: error timeout invalid_header http_502 http_503 http_504
  proxy-stream-timeout: 2m
  proxy-stream-next-upstream-timeout: 5s
  proxy-stream-next-upstream-tries: 7
  upstream-keepalive-time: 20m
```

## Backup and Restore

Pyrus Datacenter comes with an internal PostgreSQL service, which is used for data storage.\
To provide contingency measures in case of hardware failure or other disasters, the system comes with an automatic backup procedure based on [wal-g](https://github.com/wal-g/wal-g), which backs everything up to AWS S3 (or any other S3-compliant storages). \
In order to enable said functionality, you'll need to specify the following S3 parameters:

```
standalonePostgreSQLBackup:
  AWS_ACCESS_KEY_ID: <ACCESSKEY>  
  AWS_SECRET_ACCESS_KEY: <SECRETKEY>  
  WALG_S3_PREFIX: s3://<S3BUCKET>/<DIRECTORY>
```

If you want to use an S3 storage other than AWS S3:
```
standalonePostgreSQLBackup:
  AWS_ENDPOINT: <S3_URL>
```

### Backup procedure description

The backup procedure launches automatically. \
A full copy is made at 01:00 am every night. \
To change the schedule of these backups, you can use the following SQL statement inside the PostgreSQL container:

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

*RETAIN_FIND_FULL* tells the system *how many* sequential backups to store.\
Default value - 7.
 
*WALG_DELTA_MAX_STEPS* manages the amount of steps between a delta-copy and a full copy.\
Default value - 3.

You can list all scheduled jobs using the following sql command:
```
select * from cron.job;
```

### Restoring from a backup

To restore a backup you need to specify its name in the *pyrus-postgres* environment.\
For example, using the latest backup:
```
RESTORE_NAME: LATEST
```

You can list all the available backup copies with the following command:
```
wal-g backup-list
```

The restoration will only start if the ${PGDATA} directory is empty.\
Otherwise, the process will be skipped and the system will start using the data located in that directory, or re-initialize from scratch if that's empty.

